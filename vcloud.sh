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
    vpncloud config
    systemctl daemon-reload
    read -p "Press Enter To Continue"

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
    sudo rm -rf /root/vpncloud
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
