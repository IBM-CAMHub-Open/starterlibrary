# This is a terraform generated template generated from twovmfinal

provider "google" {
}

data "template_file" "gce_startup_script" {
  template = file("${path.module}/scripts/setkey.sh")
  vars = {
    gce_ssh_public_key = var.gce_ssh_public_key
    gce_ssh_user       = var.gce_ssh_user
  }
}

resource "google_compute_instance" "mariadb" {
  name         = var.mariadb_hostname
  machine_type = var.machine_type
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = var.boot_disk
    }
  }
  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }
  metadata = {
    ssh-keys = "${var.gce_ssh_user}:${var.gce_ssh_public_key}"
  }
  metadata_startup_script = data.template_file.gce_startup_script.rendered
}

resource "google_compute_instance" "php" {
  name         = var.php_hostname
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["http-server"]

  boot_disk {
    initialize_params {
      image = var.boot_disk
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }
  metadata = {
    ssh-keys = "${var.gce_ssh_user}:${var.gce_ssh_public_key}"
  }
  metadata_startup_script = data.template_file.gce_startup_script.rendered
}

resource "null_resource" "install_mariadb" {
  # Specify the ssh connection
  # Specify the ssh connection
  connection {
    user        = var.gce_ssh_user
    private_key = base64decode(var.gce_ssh_private_key)

    host                = google_compute_instance.mariadb.network_interface.0.access_config.0.nat_ip
    bastion_host        = var.bastion_host
    bastion_user        = var.bastion_user
    bastion_private_key = length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key
    bastion_port        = var.bastion_port
    bastion_host_key    = var.bastion_host_key
    bastion_password    = var.bastion_password
  }

  # Create the installation script
  # Create the installation script
  provisioner "file" {
    content = <<EOF
#!/bin/bash
LOGFILE="/var/log/install_mariadb.log"
USER=$1
PASSWORD=$2
HOST=$3
retryInstall () {
  n=0
  max=5
  command=$1
  while [ $n -lt $max ]; do
    $command && break
    let n=n+1
    if [ $n -eq $max ]; then
      echo "---Exceed maximal number of retries---"
      exit 1
    fi
    sleep 15
   done
}
echo "---start installing mariaDB---" | tee -a $LOGFILE 2>&1
retryInstall " yum install -y mariadb mariadb-server"        >> $LOGFILE 2>&1 || { echo "---Failed to install MariaDB---" | tee -a $LOGFILE; exit 1; }
systemctl start mariadb                                     >> $LOGFILE 2>&1 || { echo "---Failed to start MariaDB---" | tee -a $LOGFILE; exit 1; }
systemctl enable mariadb                                    >> $LOGFILE 2>&1 || { echo "---Failed to enable MariaDB---" | tee -a $LOGFILE; exit 1; }
mysql -e "CREATE USER '$USER'@'$HOST' IDENTIFIED BY '$PASSWORD'; GRANT ALL PRIVILEGES ON * . * TO '$USER'@'$HOST'; FLUSH PRIVILEGES;"  >> $LOGFILE 2>&1 || { echo "---Failed to add user---" | tee -a $LOGFILE; exit 1; }
firewall-cmd --state >> $LOGFILE 2>&1
if [ $? -eq 0 ] ; then
  firewall-cmd --zone=public --add-port=3306/tcp --permanent  >> $LOGFILE 2>&1 || { echo "---Failed to open port 3306---" | tee -a $LOGFILE; exit 1; }
  firewall-cmd --reload                                       >> $LOGFILE 2>&1 || { echo "---Failed to reload firewall---" | tee -a $LOGFILE; exit 1; }
fi
echo "---finish installing mariaDB---" | tee -a $LOGFILE 2>&1
EOF


    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/installation.sh; sudo bash /tmp/installation.sh \"${var.mariadb_user}\" \"${var.mariadb_pwd}\" \"${google_compute_instance.php.network_interface.0.network_ip}\"",
    ]
  }
}

resource "null_resource" "install_php" {
  depends_on = [null_resource.install_mariadb]

  # Specify the ssh connection
  # Specify the ssh connection
  connection {
    host        = google_compute_instance.php.network_interface.0.access_config.0.nat_ip
    user        = var.gce_ssh_user
    private_key = base64decode(var.gce_ssh_private_key)

    bastion_host        = var.bastion_host
    bastion_user        = var.bastion_user
    bastion_private_key = length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key
    bastion_port        = var.bastion_port
    bastion_host_key    = var.bastion_host_key
    bastion_password    = var.bastion_password
  }

  # Create the installation script
  # Create the installation script
  provisioner "file" {
    content = <<EOF
#!/bin/bash
LOGFILE="/var/log/install_php.log"
PHP_HOST=$1
MYSQL_HOST=$2
MYSQL_USER=$3
MYSQL_PWD=$4
retryInstall () {
  n=0
  max=5
  command=$1
  while [ $n -lt $max ]; do
    $command && break
    let n=n+1
    if [ $n -eq $max ]; then
      echo "---Exceed maximal number of retries---"
      exit 1
    fi
    sleep 15
   done
}
echo "---start installing apache---" | tee -a $LOGFILE 2>&1
retryInstall "yum install -y httpd"                       >> $LOGFILE 2>&1 || { echo "---Failed to install apache---" | tee -a $LOGFILE; exit 1; }
systemctl start httpd                                     >> $LOGFILE 2>&1 || { echo "---Failed to start apache---" | tee -a $LOGFILE; exit 1; }
systemctl enable httpd                                    >> $LOGFILE 2>&1 || { echo "---Failed to enable apache---" | tee -a $LOGFILE; exit 1; }
firewall-cmd --state >> $LOGFILE 2>&1
if [ $? -eq 0 ] ; then
  firewall-cmd --zone=public --add-port=80/tcp --permanent  >> $LOGFILE 2>&1 || { echo "---Failed to open port 80---" | tee -a $LOGFILE; exit 1; }
  firewall-cmd --reload                                     >> $LOGFILE 2>&1 || { echo "---Failed to reload firewall---" | tee -a $LOGFILE; exit 1; }
fi
mkdir -p /var/www/html/$PHP_HOST/public_html              >> $LOGFILE 2>&1 || { echo "---Failed to create directory for web pages---" | tee -a $LOGFILE; exit 1; }
mkdir -p /var/log/httpd/$PHP_HOST/logs                    >> $LOGFILE 2>&1 || { echo "---Failed to create directory for apache logs---" | tee -a $LOGFILE; exit 1; }
cat << EOT > /etc/httpd/conf.d/virtualHost.conf
<Directory /var/www/html/$PHP_HOST/public_html>
    Require all granted
</Directory>
<VirtualHost *:80>
        ServerName $PHP_HOST
        ServerAdmin camadmin@localhost
        DocumentRoot /var/www/html/$PHP_HOST/public_html
        ErrorLog /var/log/httpd/$PHP_HOST/logs/error.log
        CustomLog /var/log/httpd/$PHP_HOST/logs/access.log combined
</VirtualHost>
EOT
systemctl restart httpd                                   >> $LOGFILE 2>&1 || { echo "---Failed to restart apache---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing apache---" | tee -a $LOGFILE 2>&1
echo "---start installing php---" | tee -a $LOGFILE 2>&1
retryInstall "yum install -y php php-mysql php-gd php-pear"  >> $LOGFILE 2>&1 || { echo "---Failed to install php---" | tee -a $LOGFILE; exit 1; }
cat << EOT > /var/www/html/$PHP_HOST/public_html/test.php
<html>
<head>
    <title>PHP Test</title>
</head>
    <body>
    <?php echo '<p>Thanks for trying the CAM Lamp stack starter pack</p>';
    // In the variables section below, replace user and password with your own MariaDB credentials as created on your server
    \$servername = "$MYSQL_HOST";
    \$username = "$MYSQL_USER";
    \$password = "$MYSQL_PWD";
    // Create MySQL connection
    \$conn = mysqli_connect(\$servername, \$username, \$password);
    // Check connection - if it fails, output will include the error message
    if (!\$conn) {
        die('<p>Connection failed: <p>' . mysqli_connect_error());
    }
    echo '<p>Connected successfully to MariaDB</p>';
    echo '<p>If you would like more information on IBM\'s cloud management products, checkout this <a href="https://www.ibm.com/cloud-computing/products/cloud-management/">link</a></p>';
    ?>
</body>
</html>
EOT
sestatus | grep 'enabled' >> $LOGFILE 2>&1
if [ $? == 0 ]; then
   setsebool -P httpd_can_network_connect=1                  >> $LOGFILE 2>&1 || { echo "---Failed to change SELinux permission---" | tee -a $LOGFILE; exit 1; }
fi
systemctl restart httpd                                   >> $LOGFILE 2>&1 || { echo "---Failed to restart apache---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing php---" | tee -a $LOGFILE 2>&1
EOF


    destination = "/tmp/installation.sh"
  }

  # Execute the script remotely
  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/installation.sh; sudo bash /tmp/installation.sh \"${google_compute_instance.php.network_interface.0.network_ip}\" \"${google_compute_instance.mariadb.network_interface.0.network_ip}\" \"${var.mariadb_user}\" \"${var.mariadb_pwd}\"",
    ]
  }
}

