#!/bin/bash

# Install Prerequisites
apt-get update
apt-get install -y autoconf gcc libc6 make wget unzip apache2 apache2-utils php libgd-dev

# Unzip and Compile Nagios Core
cd /tmp
wget -O /tmp/nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.4.3.tar.gz
tar xzf /tmp/nagioscore.tar.gz

cd /tmp/nagioscore-nagios-4.4.3/
./configure --with-httpd-conf=/etc/apache2/sites-enabled
make all

# Create Users and Groups
make install-groups-users
usermod -aG nagios www-data

# Install Binaries, Service/Daemon, Command Mode, Configuration Files
make install
make install-daemoninit
make install-commandmode
make install-config

# Install Apache Config files
make install-webconf
a2enmod rewrite
a2enmod cgi 

# Create Firewall rules allowing port 80
iptables -I INPUT -p tcp --destination-port 80 -j ACCEPT
apt-get install -y iptables-persistent

# Create Default Nagios Admin user.
htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin

# Enable and start Nagios services
systemctl start nagios
systemctl enable nagios
systemctl restart apache2
systemctl enable apache2

# Install Prerequisites for Nagios Plugins
apt-get install -y autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext

# Unpack Plugins
cd /tmp
wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
tar xzf nagios-plugins.tar.gz

# Compile and install Plugins
cd /tmp/nagios-plugins-release-2.2.1/
./tools/setup
./configure
make 
make install

systemctl restart nagios

# Prompt for a password reset
printf "Nagios has been successfully installed. \nThe default user is: nagiosadmin\nThe default password is: nagiosadmin\nPlease reset this immediately once access has been confirmed. The command to reset the password is:\n htpasswd /usr/local/nagios/etc/htpasswd.users nagiosadmin\nYou can access the server by opening a web browser and navigating to the following URL: http://fqdn/nagios\n\n"

read -p "Would you like to reset the password now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    printf "Resetting Password for nagiosadmin user...\n"
    htpasswd /usr/local/nagios/etc/htpasswd.users nagiosadmin
elif [[ $REPLY =~ ^[Nn]$ ]]
then
    printf "Not resetting password. Exiting script\n"
    [[ $0 = $BASH_SOURCE ]] && exit 1
else
    printf "Improper output selected. Exiting script\n"
    [[ $0 = $BASH_SOURCE ]] && exit 1
fi 
