#!/bin/bash

# Installation of FirewallD
sudo yum install -y firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Installation of MariaDB
sudo yum install -y mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Configure firewall for Database
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --reload

# Create the db-create-user.sql
cat > db-create-user.sql <<-EOF
CREATE DATABASE ecomdb;
CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
FLUSH PRIVILEGES;

EOF

# Run sql script
sudo mysql < db-create-user.sql

# Create the db-load-script.sql
cat > db-load-script.sql <<-EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;

INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");

EOF

# Run sql script
sudo mysql < db-load-script.sql


##### Deploy and Configure Web #####
# Install required packages
sudo yum install -y php-mysql httpd php
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload


# Configure httpd
sudo sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf


# Start httpd
sudo systemctl start httpd
sudo systemctl enable httpd

# Download code
sudo yum install -y git
sudo git clone https://github.com/kodekloudhub/learning-app-ecommerce.git /var/www/html/


# Update index.php
sudo sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php