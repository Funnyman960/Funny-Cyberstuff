bash
#!/bin/bash

# Linux Mint System Hardening Script
# Designed for CyberPatriot

# Function to display messages
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] - $1"
}

# Update and Upgrade System
log_message "Updating and upgrading the system..."
sudo apt update && sudo apt upgrade -y

# Disable root login
log_message "Disabling root login..."
sudo passwd -l root

# Install and configure UFW (Uncomplicated Firewall)
log_message "Installing UFW and configuring firewall..."
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable

# Remove unused services
log_message "Removing unused services..."
sudo systemctl disable avahi-daemon.service
sudo systemctl stop avahi-daemon.service

# Configure automatic updates
log_message "Configuring automatic updates..."
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Create a backup of important configuration files
log_message "Backing up important configuration files..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo cp /etc/fstab /etc/fstab.bak

# Set SSH security settings
log_message "Securing SSH configuration..."
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/#ChallengeResponseAuthentication no/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/#X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Configure password policies
log_message "Setting password policies..."
echo "PASS_MAX_DAYS   90" | sudo tee -a /etc/login.defs
echo "PASS_MIN_DAYS   1" | sudo tee -a /etc/login.defs
echo "PASS_MIN_LEN    12" | sudo tee -a /etc/login.defs
echo "PASS_WARN_AGE   7" | sudo tee -a /etc/login.defs

# Install fail2ban to protect against brute-force attacks
log_message "Installing fail2ban..."
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Remove unused packages
log_message "Removing unused packages..."
sudo apt autoremove -y

# Setting file permissions for sensitive files
log_message "Setting secure permissions for sensitive files..."
sudo chmod 600 /etc/shadow
sudo chmod 600 /etc/gshadow
sudo chmod 600 /etc/passwd

# Disable unused network services
log_message "Disabling unused network services..."
sudo systemctl disable cups.service
sudo systemctl stop cups.service

# Enable auditd for logging
log_message "Installing and configuring auditd..."
sudo apt install auditd -y
sudo systemctl enable auditd
sudo systemctl start auditd

# Set up logging for login attempts
log_message "Configuring login attempt logging..."
echo "auth required pam_tally2.so deny=5 onerr=fail even_deny_root root_unlock_time=900" | sudo tee -a /etc/pam.d/common-auth

# Configure system logging
log_message "Configuring rsyslog..."
sudo sed -i 's/#*.*;auth,authpriv.none;user.none;mail.none;news.none;*.=info;*.=notice;*.=warn /var/log/messages/' /etc/rsyslog.conf
sudo systemctl restart rsyslog

# Ensure unused accounts are removed
log_message "Checking for unused accounts..."
for user in $(cut -f1 -d: /etc/passwd); do
    if [[ "$(sudo lastlog -u $user | grep "Never")" ]]; then
        log_message "User $user has never logged in; consider removing or disabling."
        # Uncomment the next line to disable account
        # sudo usermod -L $user
    fi
done

# Ensure firewall is set to start on boot
log_message "Ensuring UFW starts on boot..."
sudo systemctl enable ufw

# Logging completed
log_message "System hardening complete. Please review all changes and configurations."

# End of script