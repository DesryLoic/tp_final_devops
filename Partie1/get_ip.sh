#!/bin/bash

echo "Récupération des adresses IP depuis Terraform..."

# Récupère l'IP de la VM principale (K3s) générée par Terraform
VM_IP=$(terraform output -raw vm_ip)

# Change de dossier pour récupérer l'IP de la VM monitoring
cd ../Partie5
MONITOR_IP=$(terraform output -raw monitor_ip)

# Sécurité : Stoppe la pipeline si l'une des IPs est introuvable
if [ -z "$VM_IP" ] || [ -z "$MONITOR_IP" ]; then
    echo "Erreur : Impossible de récupérer les deux IPs. Vérifiez l'état de Terraform."
    exit 1
fi

echo "IP K3s trouvée : $VM_IP"
echo "IP Monitoring trouvée : $MONITOR_IP"

echo "Génération du fichier inventory.ini..."

cd ..

# Génère le fichier inventory.ini avec les IPs dynamiques
cat <<EOF > inventory.ini
[k3s_master]
debian-k3s ansible_host=$VM_IP

[monitoring]
debian-monitor ansible_host=$MONITOR_IP

[all:vars]
ansible_user=vagrant
ansible_password=vagrant
ansible_ssh_common_args='-o StrictHostKeyChecking=no' # Désactive la confirmation manuelle (yes/no) de la clé SSH
EOF

echo "Fichier inventory.ini mis à jour avec succès à la racine du projet !"
