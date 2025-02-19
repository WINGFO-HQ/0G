# 0G Node Installation Guide

This guide will help you install and run a 0G node. Follow these steps carefully to ensure proper installation.

## System Requirements

- Operating System: Ubuntu 20.04 or higher
- RAM: 4GB minimum
- Storage: 50GB minimum
- Root access or sudo privileges

## Quick Installation

You can install the 0G node using either curl or wget. Choose one of the following methods:

### Using curl

```bash
curl -sSL https://raw.githubusercontent.com/WINGFO-HQ/0G/main/0G.sh | sudo bash
```

### Using wget

```bash
wget -qO- https://raw.githubusercontent.com/WINGFO-HQ/0G/main/0G.sh | sudo bash
```

## Manual Installation

If you prefer to inspect the script before running it, you can:

1. Download the script:

```bash
# Using curl
curl -O https://github.com/WINGFO-HQ/0G/main/0G.sh

# Or using wget
wget https://github.com/WINGFO-HQ/0G/main/0G.sh
```

2. Make it executable:

```bash
chmod +x 0G.sh
```

3. Run the script:

```bash
sudo ./0G.sh
```

## Installation Process

The script will automatically:

1. Update your system packages
2. Install Docker and required dependencies
3. Install Git
4. Clone the 0G client repository
5. Build the Docker image
6. Prompt for your private key
7. Configure and start the node

## Private Key Input

During installation, you will be prompted to enter your private key. Make sure to:

- Remove the '0x' prefix if present
- Ensure it's a valid 64-character hexadecimal key
- Keep your private key secure and never share it

## Post-Installation

After successful installation, you can:

1. Check the node status:

```bash
docker logs -f 0g-da-client
```

2. Stop the node:

```bash
docker stop 0g-da-client
```

3. Start the node:

```bash
docker start 0g-da-client
```

## Troubleshooting

If you encounter any issues:

1. Check if Docker is running:

```bash
systemctl status docker
```

2. Verify the container status:

```bash
docker ps -a | grep 0g-da-client
```

3. View detailed logs:

```bash
docker logs 0g-da-client
```

## Support

For support, join our community:

- Telegram: https://t.me/infomindao
- Group: https://t.me/WINGFO_DAO

## Security Notice

- Always verify the script source before running it
- Never share your private key
- Use a dedicated private key for the node
- Keep your system updated and secured

## License

This project is licensed under the MIT License - see the LICENSE file for details.
