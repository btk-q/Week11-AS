#!/bin/bash

# Set up logging to make debugging easier
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting EC2 initialization script..."

# System Updates and Essential Packages
echo "Updating system packages..."
apt update -y
apt install -y git curl unzip tar gcc g++ make

# Node.js Installation via NVM
echo "Installing Node.js via NVM..."
su - ubuntu -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash'

# Install the latest LTS version of Node.js
su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install --lts'

# Set the installed version as the default
su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm alias default node'

# PM2 Installation and Configuration
echo "Installing PM2 globally..."
su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && npm install -g pm2'

# Configure PM2 to start on system boot
echo "Configuring PM2 startup..."
su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && pm2 startup'

# Generate and run the startup script with proper permissions
env PATH=$PATH:/home/ubuntu/.nvm/versions/node/$(su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && node -v')/bin /home/ubuntu/.nvm/versions/node/$(su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && node -v')/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu

# Create logs directory for the application
echo "Creating logs directory..."
su - ubuntu -c 'mkdir -p ~/logs'

# AWS CLI Installation
echo "Installing AWS CLI..."
apt install -y awscli

echo "EC2 initialization script completed!"

