#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo or run as root."
    exit 1
fi

# Function to validate IP address format
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to set static IP address
set_static_ip() {
    local interface=$1
    local ip=$2
    local subnet=$3
    local gateway=$4

    # Backup existing network configuration file
    cp /etc/network/interfaces /etc/network/interfaces.backup

    # Set static IP configuration
    cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto $interface
iface $interface inet static
address $ip
netmask $subnet
gateway $gateway
EOF

    # Restart networking service
    systemctl restart networking
}

# Main script

# List available network interfaces
echo "Available network interfaces:"
ip -o link show | awk -F': ' '{print $2}'

# Prompt user for network interface
read -p "Enter the network interface you want to configure (e.g., eth0): " interface

# Prompt user for IP address
read -p "Enter the local IP address for interface $interface: " ip
while ! validate_ip $ip; do
    read -p "Invalid IP address format. Please enter a valid IP address: " ip
done

# Prompt user for subnet mask
read -p "Enter the subnet mask for interface $interface: " subnet
while ! validate_ip $subnet; do
    read -p "Invalid subnet mask format. Please enter a valid subnet mask: " subnet
done

# Prompt user for default gateway
read -p "Enter the default gateway for interface $interface: " gateway
while ! validate_ip $gateway; do
    read -p "Invalid gateway format. Please enter a valid gateway IP address: " gateway
done

# Set static IP
set_static_ip $interface $ip $subnet $gateway

echo "Static IP address for interface $interface configured successfully!"
echo "Rebooting the system in 10 seconds..."
sleep 10
reboot
