#!/bin/bash

function print_color() {
    NC='\033[0m' # No color
    case $1 in
        "green") COLOR='\033[0;32m';;
        "red") COLOR='\033[0;31m';;
        "*") COLOR='\033[0m';;
    esac

    echo -e "${COLOR} $2 ${NC}"
}


function check_service_status() {
    service_is_active=$(sudo systemctl is-active $1)

    if [ $service_is_active = "active" ]
    then
        echo "$1 is active and running"
    else
        echo "$1 is not active/running"
        exit 1
    fi
}

function is_firewalld_rule_configured(){

    firewalld_ports=$(sudo firewall-cmd --list-all --zone=public | grep ports)

    if [[ $firewalld_ports == *$1* ]]
    then
        echo "FirewallD has port $1 configured"
    else
        echo "FirewallD port $1 is not configured"
        exit 1
    fi
}


function check_item(){
    if [[ $1 = *$2* ]]
    then
        print_color "green" "Item $2 is present on the web page"
    else
        print_color "red" "Item $2 is not present on the web page"
    fi
}

echo "------------------- Setup Database Server ------------------------"

# Installation of FirewallD
print_color "green" "Installing FirewallD..."
sudo yum install -y firewalld
print_color "green" "Starting FirewallD..."
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Check FirewallD Service is running
check_service_status firewalld

# Installation of MariaDB
print_color "green" "Installing MariaDB Server..."
sudo yum install -y mariadb-server
print_color "green" "Starting MariaDB Server..."
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Check MariaDB Service is running
check_service_status mariadb

# Configure firewall for Database
print_color "green" "Configuring FirewallD for database..."
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --reload

# Create the db-create-user.sql
print_color "green" "Setting up database..."
cat > db-create-user.sql <<-EOF
CREATE DATABASE ecomdb;
CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
FLUSH PRIVILEGES;

EOF
# Run sql script
sudo mysql < db-create-user.sql

# Create the db-load-script.sql
print_color "green" "Loading inventory data into database..."
cat > db-load-script.sql <<-EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;

INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");

EOF

# Run sql script
sudo mysql < db-load-script.sql

# Check if data is loaded to the DB
mysql_db_results=$(sudo mysql -e "use ecomdb; select * from products;")

if [[ $mysql_db_results == *Laptop* ]]
then
    print_color "green" "Inventory data loadded into MySQL"
else
    print_color "green" "Inventory data not loaded into MySQL"
    exit 1
fi

print_color "green" "-------------------------- Setup Database Server - Finished ---------------------"



print_color "green" "-------------------------- Setup Web Server ------------------------"


##### Deploy and Configure Web #####
# Install required packages
print_color "green" "Installing Web Server Packages..."
sudo yum install -y php-mysqlnd httpd php
print_color "green" "Configuring FirewallD rules..."
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload

is_firewalld_rule_configured 80


# Configure httpd
print_color "green" "Configuring httpd files..."
sudo sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf


# Start httpd
print_color "green" "Start http service..."
sudo systemctl start httpd
sudo systemctl enable httpd

# Download code
print_color "green" "Installing Git and clonning repos..."
sudo yum install -y git
sudo git clone https://github.com/kodekloudhub/learning-app-ecommerce.git /var/www/html/


# Update index.php
print_color "green" "Updating index.php..."
sudo sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php

print_color "green" "-------------------------- Setup Web Server - Finished ------------------------"


# Test Script
web_page=$(curl http://localhost)

for item in Laptop Drone VR Watch Phone
do
    check_item "$web_page" $item
done
