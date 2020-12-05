#!/bin/bash
egrep -i "^${gce_ssh_user}:" /etc/passwd;
if [ $? -eq 0 ]; then
   echo "User ${gce_ssh_user} Exists"
else
   echo "User does not exist create user ${gce_ssh_user} ..."
   useradd -m ${gce_ssh_user}
   usermod -aG wheel ${gce_ssh_user}
   echo '%wheel        ALL=(ALL)       NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
fi
SSHD_CONFIG_FILE="/etc/ssh/sshd_config"
SSH_CONFIG_DIR="/home/${gce_ssh_user}/.ssh"
if [[ ${gce_ssh_user} == "root" ]]; then
    SSH_CONFIG_DIR="/root/.ssh"
fi
mkdir -p $SSH_CONFIG_DIR
cat > $SSH_CONFIG_DIR/authorized_keys <<-EOT
${gce_ssh_public_key}
EOT
 if [[ ${gce_ssh_user} == "root" ]]; then
    echo "User is root, permit root login ..."
    sed -i -e 's/PermitRootLogin no/PermitRootLogin without-password/' $SSHD_CONFIG_FILE
    systemctl restart sshd        
fi

   
