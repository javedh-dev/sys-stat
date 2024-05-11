#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check mark symbol
CHECK_MARK='\xE2\x9C\x94'

# Cross mark symbol
CROSS_MARK='\xE2\x9C\x98'

# Dash symbol
DASH='-'

# Function to display step messages in green
step_message() {
    echo -e "${GREEN}$1${NC}"
}

# Function to display success messages with check mark
success_message() {
    echo -e "${GREEN}${CHECK_MARK} $1${NC}"
}

# Function to display failure messages with cross mark
failure_message() {
    echo -e "${RED}${CROSS_MARK} $1${NC}"
}

# Check if the system is Debian, otherwise exit with a message
check_debian() {
    step_message "Checking system compatibility..."
    if [ ! -f /etc/debian_version ]; then
        failure_message "This script is intended for Debian-based systems only."
        exit 1
    fi
    success_message "System is compatible."
}

# Download and install speedtest from Ookla and add it to the path
install_speedtest() {
    step_message "Downloading and installing Speedtest..."
    wget -O speedtest.tgz https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz
    tar -xvf speedtest.tgz
    if [ $? -eq 0 ]; then
        chmod +x speedtest
        mv speedtest /usr/local/bin/
        success_message "Speedtest installed successfully."
    else
        failure_message "Failed to download Speedtest."
    fi
    rm -rf speedtest*
}

# Install required packages non-interactively
install_packages() {
    step_message "Installing required packages..."
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y jq python3 python3-venv iperf3
    if [ $? -eq 0 ]; then
        success_message "Required packages installed."
    else
        failure_message "Failed to install required packages."
    fi
}

# Create a service called sys-stats
create_sys_stats_service() {
    step_message "Creating sys-stats service..."
    cat <<EOF > /etc/systemd/system/sys-stats.service
[Unit]
Description=System Statistics Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/share/sys-stats/.venv/bin/python /usr/local/bin/sys-stats.py
EnvironmentFile=/usr/share/sys-stats/.env
WorkingDirectory=/usr/share/sys-stats
User=root

[Install]
WantedBy=multi-user.target
EOF
    if [ $? -eq 0 ]; then
        success_message "Sys-stats service created."
    else
        failure_message "Failed to create sys-stats service."
    fi
}

# Copy config.yml to /usr/share/sys-stats
copy_config_file() {
    step_message "Copying config.yml..."
    mkdir -p /usr/share/sys-stats/
    cp -n config.yml /usr/share/sys-stats/
    step_message "Copying env file..."
    cp -n env.txt /usr/share/sys-stats/.env
    if [ $? -eq 0 ]; then
        success_message "Config file copied."
    else
        failure_message "Failed to copy config file."
    fi
}

# Copy fetch-temp file to /usr/local/bin and make it executable
copy_binaries() {
    step_message "Copying fetch-temp and app.py file to /usr/local/bin and making it executable..."
    
    cp app.py /usr/local/bin/sys-stats.py
    cp fetch-temp /usr/local/bin/
    if [ $? -eq 0 ]; then
        chmod +x /usr/local/bin/fetch-temp
        chmod +x /usr/local/bin/sys-stats.py
        success_message "fetch-temp and app.py copied and made executable successfully."
    else
        failure_message "Failed to copy fetch-temp or app.py file."
    fi
}

# Create Python virtual environment and install requirements
setup_virtual_environment() {
    step_message "Setting up virtual environment and installing requirements..."
    mkdir -p /usr/share/sys-stats/.venv
    python3 -m venv /usr/share/sys-stats/.venv
    source /usr/share/sys-stats/.venv/bin/activate
    pip install -r requirements.txt
    if [ $? -eq 0 ]; then
        success_message "Virtual environment set up."
    else
        failure_message "Failed to set up virtual environment."
    fi
}

# Enable and start the service
enable_and_start_service() {
    step_message "Enabling and starting the service..."
    systemctl enable sys-stats
    systemctl start sys-stats
    if [ $? -eq 0 ]; then
        success_message "Service enabled and started."
    else
        failure_message "Failed to enable and start the service."
    fi
}

# Uninstall Speedtest
uninstall_speedtest() {
    step_message "Uninstalling Speedtest..."
    rm /usr/local/bin/speedtest
    if [ $? -eq 0 ]; then
        success_message "Speedtest uninstalled successfully."
    else
        failure_message "Failed to uninstall Speedtest."
    fi
}

# Uninstall required packages
uninstall_packages() {
    step_message "Uninstalling required packages..."
    apt-get purge -y jq python3-venv iperf3
    if [ $? -eq 0 ]; then
        success_message "Required packages uninstalled."
    else
        failure_message "Failed to uninstall required packages."
    fi
}

# Disable and stop the service
disable_and_stop_service() {
    step_message "Disabling and stopping the service..."
    systemctl stop sys-stats
    systemctl disable sys-stats
    if [ $? -eq 0 ]; then
        success_message "Service disabled and stopped."
    else
        failure_message "Failed to disable and stop the service."
    fi
}

# Remove sys-stats service
remove_sys_stats_service() {
    step_message "Removing sys-stats service..."
    rm /etc/systemd/system/sys-stats.service
    if [ $? -eq 0 ]; then
        success_message "Sys-stats service removed."
    else
        failure_message "Failed to remove sys-stats service."
    fi
}

# Remove sys-stats directory
clear_sys_stats_directory() {
    step_message "Removing sys-stats directory..."
    rm -rf /usr/share/sys-stats/.venv
    if [ $? -eq 0 ]; then
        success_message "Sys-stats directory removed."
    else
        failure_message "Failed to remove sys-stats directory."
    fi
}

# Uninstall Python virtual environment
uninstall_virtual_environment() {
    step_message "Uninstalling virtual environment..."
    rm -rf /usr/share/sys-stats/.venv
    if [ $? -eq 0 ]; then
        success_message "Virtual environment uninstalled."
    else
        failure_message "Failed to uninstall virtual environment."
    fi
}

# Main function to execute all uninstallation steps
uninstall() {
    uninstall_speedtest
    uninstall_packages
    disable_and_stop_service
    remove_sys_stats_service
    remove_sys_stats_directory
    uninstall_virtual_environment
}

# Main function to execute all steps
install() {
    check_debian
    install_speedtest
    install_packages
    copy_config_file
    copy_binaries
    create_sys_stats_service
    setup_virtual_environment
    enable_and_start_service
}


# Clone repository into a temporary directory and delete it at the end
main() {
    step_message "Cloning repository into temporary directory..."
    temp_dir=$(mktemp -d)
    git clone https://github.com/javedh-dev/sys-stat.git "$temp_dir"
    if [ $? -eq 0 ]; then
        cd "$temp_dir"
        install
        cd ..
        rm -rf "$temp_dir"
        success_message "Repository cloned and cleaned up."
    else
        failure_message "Failed to clone repository."
    fi
}


# Parse command line arguments
if [ "$1" == "uninstall" ]; then
    uninstall
else
    main
fi