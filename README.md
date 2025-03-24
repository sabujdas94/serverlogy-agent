# Serverlogy Agent

The **Serverlogy Agent** is a lightweight server management tool designed to simplify the deployment and management of server-side applications. It automates the setup of essential components such as Flask, Gunicorn, SSL certificates, and systemd services, ensuring a secure and efficient server environment.

## Features

- Automated installation of dependencies (Python, Flask, Gunicorn, etc.).
- Self-signed SSL certificate generation for secure communication.
- Systemd service setup for auto-start and process management.
- UFW firewall configuration for enhanced security.
- Passwordless sudo configuration for the specified user.

## Getting Started

To set up the Serverlogy Agent, run the `setup_agent.sh` script with the desired username as an argument:

```bash
sudo bash setup_agent.sh <username>
```

Replace `<username>` with the name of the user for whom the agent is being set up.

## Contributing

We welcome contributions from the community! If you'd like to contribute:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Submit a pull request with a clear description of your changes.

Feel free to open issues for any bugs or feature requests.

## License

This project is licensed for **personal use only**. Redistribution, commercial use, or modification for non-personal purposes is not permitted without prior written consent.

---
**Happy Coding!**
