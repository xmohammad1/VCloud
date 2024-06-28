#!/bin/bash

CONFIG_FILE="/etc/vpncloud/expert.net"

Install_vpncloud() {
    mkdir /root/vpncloud
    cd /root/vpncloud
    wget https://github.com/dswd/vpncloud/releases/download/v2.3.0/vpncloud_2.3.0_amd64.deb
    dpkg -i vpncloud_2.3.0_amd64.deb
}

setup_vpncloud() {
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo "Server IP: $SERVER_IP"
    read -p "Node Public IP: " remote_ip
    if [ -f "$CONFIG_FILE" ]; then
        sudo sed -i "/^peers:/a\\  - $remote_ip" "$CONFIG_FILE"
        restart_service
    else
        read -p "Private IP e.g 10.0.50.x : " private_ip
        sudo tee "$CONFIG_FILE" > /dev/null << EOF
---
device:
  type: tun
  name: vpncloud%d
  path: ~
  fix-rp-filter: false
ip: $private_ip
ifup: ~
ifdown: ~
crypto:
  password: ""
  private-key: ~
  public-key: ~
  trusted-keys: []
  algorithms: []
listen: "3210"
peers:
  - $remote_ip
peer-timeout: 5
keepalive: 2
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
        systemctl daemon-reload
        sudo service vpncloud@expert start
        sudo systemctl enable vpncloud@expert
        echo "VPNCloud configuration file created at $CONFIG_FILE"
        echo "This Server IP: $SERVER_IP"
        echo "This Server VPNCloud IP: $private_ip"
        read -p "Press Enter To Continue"
    fi
}

restart_service() {
    sudo service vpncloud@expert restart
}

remove_vpncloud() {
    for service in $(systemctl list-units --type=service | grep 'vpncloud@' | awk '{print $1}'); do
        echo "Stopping $service..."
        sudo systemctl stop $service
        sudo systemctl disable $service
    done
    sudo apt-get remove --purge -y vpncloud
    sudo rm -rf /etc/vpncloud
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
