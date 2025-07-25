#!/bin/bash

# Jetson Orin Network Configuration Script
# Uses JSON configuration for external and camera networks
# Based on MAC addresses: enP1p1s0 (external) and enP8p1s0 (camera)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration file
CONFIG_FILE="network_config.json"

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        log "Installing jq..."
        apt update && apt install -y jq
    fi
}

# Load JSON configuration
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        error "Configuration file $CONFIG_FILE not found"
        exit 1
    fi
    
    log "Loading configuration from $CONFIG_FILE"
}

# Get value from JSON config
get_json_value() {
    local key=$1
    jq -r "$key" "$CONFIG_FILE"
}

# Install required packages
install_packages() {
    log "Installing required packages..."
    
    # Check if ifupdown is installed
    if ! dpkg -l | grep -q ifupdown; then
        apt update
        apt install -y ifupdown net-tools
        log "Installed ifupdown and net-tools"
    else
        log "Required packages already installed"
    fi
}

# Disable NetworkManager completely
disable_networkmanager() {
    log "Disabling NetworkManager to prevent conflicts..."
    
    # Stop and disable NetworkManager
    systemctl stop NetworkManager 2>/dev/null || true
    systemctl disable NetworkManager 2>/dev/null || true
    
    # Create NetworkManager config directory
    mkdir -p /etc/NetworkManager/conf.d
    
    # Set all interfaces as unmanaged
    cat > /etc/NetworkManager/conf.d/99-unmanaged-all.conf << EOF
[keyfile]
unmanaged-devices=interface-name:enP1p1s0;interface-name:enP8p1s0;interface-name:enP*

EOF
    
    log "NetworkManager disabled for all managed interfaces"
}

# Enable networking service
enable_networking() {
    log "Enabling networking service..."
    systemctl enable networking 2>/dev/null || true
    log "Networking service enabled"
}

# Create /etc/network/interfaces configuration
create_network_config() {
    local external_interface=$(get_json_value '.external_network.interface')
    local external_ip=$(get_json_value '.external_network.ip_address')
    local external_gateway=$(get_json_value '.external_network.gateway')
    local external_netmask=$(get_json_value '.external_network.netmask')
    local external_dns=$(get_json_value '.external_network.dns_servers | join(" ")')
    
    local camera_interface=$(get_json_value '.camera_network.interface')
    local camera_ip=$(get_json_value '.camera_network.ip_address')
    local camera_gateway=$(get_json_value '.camera_network.gateway')
    local camera_netmask=$(get_json_value '.camera_network.netmask')
    
    log "Creating network configuration..."
    log "External interface: $external_interface ($external_ip)"
    log "Camera interface: $camera_interface ($camera_ip)"
    
    # Backup existing configuration
    if [[ -f /etc/network/interfaces ]]; then
        cp /etc/network/interfaces /etc/network/interfaces.backup.$(date +%Y%m%d_%H%M%S)
        log "Backed up existing /etc/network/interfaces"
    fi
    
    # Create new configuration
    cat > /etc/network/interfaces << EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# External network interface (enP1p1s0)
auto $external_interface
iface $external_interface inet static
    address $external_ip
    netmask $external_netmask
    gateway $external_gateway
    dns-nameservers $external_dns

# Camera network interface (enP8p1s0)
auto $camera_interface
iface $camera_interface inet static
    address $camera_ip
    netmask $camera_netmask
    gateway $camera_gateway

EOF
    
    log "Created /etc/network/interfaces configuration"
}

# Disable NetworkManager for the interfaces
disable_networkmanager() {
    local external_interface=$(get_json_value '.external_network.interface')
    local camera_interface=$(get_json_value '.camera_network.interface')
    
    log "Disabling NetworkManager for interfaces $external_interface and $camera_interface"
    
    # Create NetworkManager configuration to ignore the interfaces
    mkdir -p /etc/NetworkManager/conf.d
    cat > /etc/NetworkManager/conf.d/99-unmanaged.conf << EOF
[keyfile]
unmanaged-devices=interface-name:$external_interface;interface-name:$camera_interface

EOF
    
    log "NetworkManager will ignore interfaces $external_interface and $camera_interface"
}

# Restart networking services
restart_networking() {
    log "Restarting networking services..."
    
    # Disable NetworkManager completely
    disable_networkmanager
    enable_networking
    
    # Bring down existing interfaces first
    local external_interface=$(get_json_value '.external_network.interface')
    local camera_interface=$(get_json_value '.camera_network.interface')
    
    log "Bringing down existing interfaces..."
    ifdown $external_interface 2>/dev/null || true
    ifdown $camera_interface 2>/dev/null || true
    
    # Wait a moment
    sleep 2
    
    # Restart networking
    systemctl restart networking
    
    log "Networking services restarted (NetworkManager disabled)"
}

# Test network connectivity
test_connectivity() {
    local external_ip=$(get_json_value '.external_network.ip_address')
    local external_gateway=$(get_json_value '.external_network.gateway')
    local camera_ip=$(get_json_value '.camera_network.ip_address')
    local camera_gateway=$(get_json_value '.camera_network.gateway')
    local camera_target=$(get_json_value '.camera_network.camera_ip')
    
    log "Testing network connectivity..."
    
    # Wait a moment for interfaces to come up
    sleep 5
    
    # Test external interface
    if ip addr show | grep -q "$external_ip"; then
        log "External interface IP configured successfully"
    else
        error "External interface IP configuration failed"
        return 1
    fi
    
    # Test camera interface
    if ip addr show | grep -q "$camera_ip"; then
        log "Camera interface IP configured successfully"
    else
        error "Camera interface IP configuration failed"
        return 1
    fi
    
    # Test external gateway connectivity
    if ping -c 3 -W 5 "$external_gateway" > /dev/null 2>&1; then
        log "External gateway connectivity test passed"
    else
        warning "External gateway connectivity test failed"
    fi
    
    # Test camera gateway connectivity
    if ping -c 3 -W 5 "$camera_gateway" > /dev/null 2>&1; then
        log "Camera gateway connectivity test passed"
    else
        warning "Camera gateway connectivity test failed"
    fi
    
    # Test camera connectivity
    if ping -c 3 -W 5 "$camera_target" > /dev/null 2>&1; then
        log "Camera connectivity test passed"
    else
        warning "Camera connectivity test failed - check camera power and network"
    fi
}

# Show current configuration
show_config() {
    log "Current network configuration:"
    echo ""
    echo "External Network:"
    echo "  Interface: $(get_json_value '.external_network.interface')"
    echo "  MAC: $(get_json_value '.external_network.mac_address')"
    echo "  IP: $(get_json_value '.external_network.ip_address')"
    echo "  Gateway: $(get_json_value '.external_network.gateway')"
    echo ""
    echo "Camera Network:"
    echo "  Interface: $(get_json_value '.camera_network.interface')"
    echo "  MAC: $(get_json_value '.camera_network.mac_address')"
    echo "  IP: $(get_json_value '.camera_network.ip_address')"
    echo "  Gateway: $(get_json_value '.camera_network.gateway')"
    echo "  Camera IP: $(get_json_value '.camera_network.camera_ip')"
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -c, --config   Show current configuration"
    echo "  -t, --test     Test mode (don't apply changes)"
    echo "  -a, --apply    Apply network configuration"
    echo ""
    echo "This script configures dual network interfaces for Jetson Orin:"
    echo "  - External network (enP1p1s0) for internet access"
    echo "  - Camera network (enP8p1s0) for camera communication"
}

# Safely restore network configuration
restore_network_config() {
    log "Restoring network configuration..."
    
    # Stop NetworkManager
    systemctl stop NetworkManager
    
    # Find the most recent backup
    local backup_file=$(ls -t /etc/network/interfaces.backup.* 2>/dev/null | head -1)
    
    if [[ -n "$backup_file" ]]; then
        cp "$backup_file" /etc/network/interfaces
        log "Restored from backup: $backup_file"
    else
        # Create a basic configuration
        cat > /etc/network/interfaces << EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

EOF
        log "Created basic network configuration"
    fi
    
    # Restart networking
    systemctl restart networking
    systemctl start NetworkManager
    
    log "Network configuration restored"
}

# Main function
main() {
    log "Starting Jetson Orin Dual Network Configuration"
    
    # Check root privileges
    check_root
    
    # Check and install jq
    check_jq
    
    # Load configuration
    load_config
    
    # Show current configuration
    show_config
    
    # Install required packages
    install_packages
    
    # Create network configuration
    create_network_config
    
    # Restart networking with error handling
    if ! restart_networking; then
        error "Failed to restart networking services"
        warning "Attempting to restore previous configuration..."
        restore_network_config
        exit 1
    fi
    
    # Test connectivity
    test_connectivity
    
    log "Dual network configuration completed successfully!"
    info "You may need to reboot for all changes to take effect"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    -c|--config)
        check_jq
        load_config
        show_config
        exit 0
        ;;
    -t|--test)
        log "Test mode - showing configuration without applying"
        check_jq
        load_config
        show_config
        exit 0
        ;;
    -a|--apply|"")
        main
        ;;
    *)
        error "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac 