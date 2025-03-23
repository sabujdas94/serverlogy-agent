#!/bin/bash

# Callback URL for sending updates
CALLBACK_URL="https://webhook.site/7b08bd8e-60ef-42ec-9ef5-f32e2e2546ea"

# Function to send updates to the callback URL
send_update() {
  local message="$1"
  curl -X POST -H "Content-Type: application/json" -d "{\"status\": \"$message\"}" $CALLBACK_URL
}

# Run the script in the background
(
  # Check if username is provided as an argument
  if [ -z "$1" ]; then
    send_update "Error: Username not provided."
    exit 1
  fi

  USERNAME=$1
  send_update "Starting setup for user $USERNAME."

  # Update and install dependencies
  send_update "Updating system and installing dependencies..."
  sudo apt update -y && sudo apt upgrade -y
  sudo apt install -y python3 python3-pip openssl ufw

  # Install Flask
  send_update "Installing Flask..."
  pip3 install flask

  # Install Gunicorn
  send_update "Installing Gunicorn..."
  pip3 install gunicorn

  # Generate self-signed SSL certificate
  send_update "Generating self-signed SSL certificate..."
  SSL_DIR="/etc/serverlogy"
  if [ -d "$SSL_DIR" ]; then
    sudo rm -rf $SSL_DIR
  fi
  sudo mkdir -p $SSL_DIR
  sudo chown -R $USERNAME:$USERNAME $SSL_DIR
  sudo -u $USERNAME openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout $SSL_DIR/key.pem -out $SSL_DIR/cert.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=localhost"

  # Set permissions for SSL directory and files
  send_update "Setting permissions for SSL directory and files..."
  sudo chmod 700 $SSL_DIR
  sudo chmod 600 $SSL_DIR/key.pem $SSL_DIR/cert.pem

  # Configure UFW firewall
  send_update "Configuring UFW firewall..."
  CUSTOM_PORT=58443
  sudo ufw allow $CUSTOM_PORT
  echo "y" | sudo ufw enable

  # Define the working directory for the service
  WORKING_DIR="/home/$USERNAME/serverlogy-agent"

  # Ensure the working directory exists
  send_update "Ensuring working directory exists..."
  sudo mkdir -p $WORKING_DIR
  sudo chown -R $USERNAME:$USERNAME $WORKING_DIR

  # Ensure agent.py exists in the working directory
  AGENT_SCRIPT="$WORKING_DIR/agent.py"
  if [ ! -f "$AGENT_SCRIPT" ]; then
    send_update "Creating a placeholder agent.py script..."
    sudo bash -c "cat > $AGENT_SCRIPT" <<EOL
#!/usr/bin/python3
print("Serverlogy Agent is running.")
EOL
    sudo chmod +x $AGENT_SCRIPT
    sudo chown $USERNAME:$USERNAME $AGENT_SCRIPT
  fi

  # Allow the user to execute sudo commands without a password
  send_update "Configuring sudoers to allow passwordless sudo for $USERNAME..."
  SUDOERS_FILE="/etc/sudoers.d/$USERNAME"
  sudo bash -c "echo '$USERNAME ALL=(ALL) NOPASSWD:ALL' > $SUDOERS_FILE"
  sudo chmod 440 $SUDOERS_FILE

  # Create systemd service for auto-start
  send_update "Setting up systemd service for auto-start..."
  SERVICE_FILE="/etc/systemd/system/serverlogy-agent.service"
  sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=Serverlogy Agent
After=network.target

[Service]
ExecStart=/usr/local/bin/gunicorn -w 1 -b 0.0.0.0:$CUSTOM_PORT agent:app --certfile=$SSL_DIR/cert.pem --keyfile=$SSL_DIR/key.pem
WorkingDirectory=$WORKING_DIR
Restart=always
User=$USERNAME
Group=$USERNAME
StandardOutput=append:/var/log/serverlogy-agent.log
StandardError=append:/var/log/serverlogy-agent-error.log

[Install]
WantedBy=multi-user.target
EOL

  sudo systemctl daemon-reload
  sudo systemctl enable --now serverlogy-agent

  # Check the status and logs of the service
  send_update "Checking service status and logs..."
  sudo systemctl status serverlogy-agent

  send_update "Setup complete."
) &
