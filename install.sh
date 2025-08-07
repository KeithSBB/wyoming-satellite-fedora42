#!/bin/bash
set -e

# Install system dependencies
sudo dnf install -y python3 python3-pip alsa-utils

# Create wyoming user
sudo useradd -r -s /bin/false -d /usr/local/share/wyoming-satellite wyoming 2>/dev/null || true

# Create directories
sudo mkdir -p /usr/local/share/wyoming-satellite/{wyoming_satellite,config,sounds, script,.venv}
sudo cp -r wyoming_satellite/*.py /usr/local/share/wyoming-satellite/wyoming_satellite/
sudo cp pyproject.toml /usr/local/share/wyoming-satellite/
sudo cp script/run /usr/local/share/wyoming-satellite/script/
sudo cp sounds/* /usr/local/share/wyoming-satellite/sounds/

# Set permissions
sudo chown -R wyoming:wyoming /usr/local/share/wyoming-satellite
sudo chmod -R u+rwX,go+rX /usr/local/share/wyoming-satellite
sudo chmod +x /usr/local/share/wyoming-satellite/script/run

# Run setup script
sudo -u wyoming /bin/bash -c "cd /usr/local/share/wyoming-satellite && ./script/setup"

# Create systemd service
sudo bash -c 'cat << EOF > /etc/systemd/system/wyoming-satellite.service
[Unit]
Description=Wyoming Satellite Service
After=network.target
Requires=wyoming-openwakeword.service

[Service]
User=wyoming
Group=wyoming
WorkingDirectory=/usr/local/share/wyoming-satellite
ExecStart=/usr/local/share/wyoming-satellite/script/run --uri tcp://0.0.0.0:10700 --wake-uri tcp://127.0.0.1:10400 --wake-word-name ok_nabu
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

# Configure firewall
sudo firewall-cmd --add-port=10700/tcp --permanent
sudo firewall-cmd --reload

# Configure SELinux
sudo ausearch -m avc -ts recent | audit2allow -M wyoming 2>/dev/null || true
sudo semodule -i wyoming.pp 2>/dev/null || true
sudo setenforce 1

# Start service
sudo systemctl daemon-reload
sudo systemctl enable wyoming-satellite.service
sudo systemctl start wyoming-satellite.service
