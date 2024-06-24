#!/bin/bash

CONFIG_FILE="/etc/vpncloud/configdefault.net"

Install_vpncloud() {
  echo "deb https://repo.ddswd.de/deb stable main" | sudo tee /etc/apt/sources.list.d/vpncloud.list
  wget https://repo.ddswd.de/deb/public.key -qO - | sudo tee /etc/apt/trusted.gpg.d/vpncloud.asc
  sudo apt update
  sudo apt install -y vpncloud || { echo "VPNCloud installation failed"; exit 1; }
}

setup_vpncloud() {
  read -p "Node Public IP: " remote_ip
  if [ -f "$CONFIG_FILE" ]; then
    sudo sed -i "/^peers:/a\  - \"$remote_ip\"" "$CONFIG_FILE" || { echo "Failed to add peer"; exit 1; }
    restart_service
  else
    read -p "Private IP e.g 10.0.50.1: " private_ip
    sudo tee "$CONFIG_FILE" > /dev/null << EOF
---
device:
  type: tun
  name: vpncloud%d
  path: ~
  fix-rp-filter: false
ip: $private_ip
crypto:
  password: "99waq9szss"
  private-key: ~
  public-key: ~
  trusted-keys: []
  algorithms: []
listen: "3210"
peers:
  - "$remote_ip"
peer-timeout: 300
keepalive: ~
beacon:
  store: ~
  load: ~
  interval: 3600
  password: ~
mode: normal
switch-timeout: 300
claims: []
auto-claim: true
port-forwarding: true
pid-file: ~
stats-file: ~
statsd:
  server: ~
  prefix: ~
user: ~
group: ~
hook: ~
hooks: {}
EOF
  fi
  sudo service vpncloud@configdefault start || { echo "Failed to start VPNCloud service"; exit 1; }
  sudo systemctl enable vpncloud@configdefault || { echo "Failed to enable VPNCloud service"; exit 1; }
  echo "VPNCloud configuration file created at /etc/vpncloud/configdefault.net"
}

restart_service() {
  sudo service vpncloud@configdefault restart || { echo "Failed to restart VPNCloud service"; exit 1; }
}

remove_vpncloud() {
  sudo service vpncloud@configdefault stop || { echo "Failed to stop VPNCloud service"; exit 1; }
  sudo systemctl disable vpncloud@configdefault || { echo "Failed to disable VPNCloud service"; exit 1; }
  sudo apt-get remove --purge -y vpncloud || { echo "Failed to remove VPNCloud"; exit 1; }
  sudo rm -rf /etc/vpncloud || { echo "Failed to remove VPNCloud configuration files"; exit 1; }
  echo "VPNCloud removed completely."
}

while true; do
  echo ""
  echo "1) Install VPNCloud"
  echo "2) Connect a node server"
  echo "3) Restart service"
  echo "4) Remove Completely"
  echo "9) Back"
  read -p "Enter your choice: " choice

  case $choice in
    1)
      Install_vpncloud
      ;;
    2)
      setup_vpncloud
      ;;
    3)
      restart_service
      ;;
    4)
      remove_vpncloud
      ;;
    9)
      echo "Exiting..."
      break
      ;;
    *)
      echo "Invalid option. Please try again."
      ;;
  esac
done
