#!/bin/bash

echo "Récupération des adresses IP depuis Terraform..."

# Extraction des IPs
VM_IP=$(terraform output -raw vm_ip)
MONITOR_IP=$(terraform output -raw monitor_ip)

# Vérifications
if [ -z "$VM_IP" ] || [ -z "$MONITOR_IP" ]; then
    echo "Erreur : Impossible de récupérer les deux IPs. Vérifiez l'état de Terraform."
    exit 1
fi

echo "IP K3s trouvée : $VM_IP"
echo "IP Monitoring trouvée : $MONITOR_IP"

echo "Génération du fichier inventory.ini..."

# On génère un inventaire complet avec les deux groupes
cat <<EOF > inventory.ini
[k3s_master]
debian-k3s ansible_host=$VM_IP

[monitoring]
debian-monitor ansible_host=$MONITOR_IP

[all:vars]
ansible_user=vagrant
ansible_password=vagrant
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "Fichier inventory.ini mis à jour avec succès !"
