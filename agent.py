from flask import Flask, request, jsonify
import subprocess
import ssl
import os  # Added to check for root privileges

app = Flask(__name__)

# Configuration
API_KEY = "your-secure-api-key"
ALLOWED_COMMANDS = ["ls", "pwd", "whoami", "ufw", "sudo"]  # Added "sudo" to handle specific sudo commands
PORT = 58443

# Middleware to validate API key
@app.before_request
def validate_api_key():
    if request.headers.get("X-API-Key") != API_KEY:
        return jsonify({"error": "Unauthorized"}), 401
    # Check Content-Type only for JSON payloads
    if request.endpoint == 'execute_command' and request.content_type != "application/json":
        return jsonify({"error": "Unsupported Media Type"}), 415

# `/execute` endpoint
@app.route('/execute', methods=['POST'])
def execute_command():
    data = request.json
    command = data.get("command")

    if not command:
        return jsonify({"error": "No command provided"}), 400

    base_command = command.split()[0]
    # Handle commands prefixed with `sudo`
    if base_command == "sudo":
        base_command = command.split()[1] if len(command.split()) > 1 else ""

    if base_command not in ALLOWED_COMMANDS:
        return jsonify({"error": "Command not allowed"}), 403

    # Restrict `ufw` commands to only allow specific operations
    if base_command == "ufw":
        if not (command.startswith("ufw allow") or command.startswith("ufw delete allow") or
                command.startswith("sudo ufw allow") or command.startswith("sudo ufw delete allow") or
                command == "sudo ufw status" or command == "sudo ufw show added"):
            return jsonify({"error": "Only specific 'ufw' commands are permitted"}), 403

    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, check=True)
        return jsonify({
            "command": command,
            "output": result.stdout.strip(),
            "error": result.stderr.strip()
        })
    except subprocess.CalledProcessError as e:
        return jsonify({
            "command": command,
            "error": e.stderr.strip()
        }), 500

# Run the Flask app with SSL
if __name__ == '__main__':
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    try:
        context.load_cert_chain('/etc/serverlogy/cert.pem', '/etc/serverlogy/key.pem')  # Updated paths
    except PermissionError as e:
        print(f"Error: {e}. Ensure the application has the necessary permissions to access the SSL files.")
        exit(1)  # Exit the application if SSL files cannot be accessed
    app.run(host='0.0.0.0', port=PORT, ssl_context=context)
