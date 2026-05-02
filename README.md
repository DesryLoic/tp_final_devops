# Documentation - TP Final DevOps : API Lacets Connectés

## Contexte Global
Ce projet s'inscrit dans le cadre du développement d'une startup concevant un concept novateur de lacets connectés. Afin de supporter l'évolution rapide de la clientèle, l'objectif de cette infrastructure est de déployer automatiquement l'API de suivi avec un maximum de fiabilité, de scalabilité et d'observabilité. L'ensemble des processus a été conçu pour être le plus idempotent possible.

---

## Arborescence du projet

La structure a été pensée pour séparer strictement les responsabilités et offrir une lisibilité maximale de l'infrastructure as Code (IaC), de la configuration et de l'orchestration :

    .
    ├── .github/
    │   └── workflows/
    │       └── deploy.yml          # Pipeline CI/CD GitHub Actions (Runner Self-Hosted)
    ├── Partie1/                    # Infrastructure as Code (K3s)
    │   ├── deploy.tf               # Provisionnement de la VM K3s (Terraform)
    │   ├── get_ip.sh               # Script Bash de récupération d'IP dynamique
    │   ├── inventory.ini           # Inventaire Ansible généré automatiquement
    │   └── install_k3s.yml         # Playbook d'installation de l'orchestrateur
    ├── Partie2/                    # Conteneurisation (Docker)
    │   └── api-lacets/
    │       ├── Dockerfile          # Build multi-stage optimisé pour la production
    │       └── ...                 # Code source Node.js de l'API
    ├── Partie3/                    # Orchestration (Kubernetes)
    │   ├── api.yaml                # Manifestes API (Deployment, Service, HPA)
    │   └── mysql.yaml              # Manifestes Database (Stateful, PVC, ConfigMap, Service)
    ├── Partie5/                    # Monitoring & Observabilité
    │   ├── monitoring.tf           # Provisionnement de la VM de Monitoring (Terraform)
    │   ├── prometheus.yml          # Configuration dynamique du scraping Prometheus
    │   └── setup_monitoring.yml    # Playbook Ansible (Node Exporter, Prometheus, Grafana)
    └── README.md                   # Documentation complète du projet
    └── .gitignore                  # Retirer du git les fichiers encombrant

---

## Partie 1 : Préparation de l'infrastructure

L'objectif est d'avoir une infrastructure prête à accueillir l'application et ce 100% automatisée.

### 1. Provisionnement des VM (Terraform)
Nous utilisons **Terraform** pour définir l'infrastructure matérielle. Le fichier `deploy.tf` configure une machine Debian sur VirtualBox (avec 2 Go de mémoire recommandée). 

### 2. Récupération dynamique des IP et Inventaire
Les VM recevant des adresses IP via DHCP, la pipeline utilise un script bash `get_ip.sh` pour récupérer l'IP réelle des machines (K3s et Monitoring). Ce script automatise la création d'un fichier `inventory.ini` Ansible.

### 3. Installation de K3s
L'installation du cluster **K3s** sur la VM principale est automatisée. Cela permet un déploiement rapide d'un cluster Kubernetes.

---

## Partie 2 : Conteneurisation de l'application

Le code source de l'API Node-Express-REST-API-MySQL a été conteneurisé en faisant attention à l'optimisation de la taille de l'image.

### 1. Optimisation du Dockerfile
Le `Dockerfile` de l'API Node.js suit les standards de production pour maximiser la sécurité et la performance :
* **Multi-stage build** : Divise drastiquement la taille de l'image finale en ne conservant que le runtime nécessaire à l'exécution.
* **Image Alpine** : Utilisation de l'image `node:alpine` pour limiter la surface d'attaque.
* **Privilèges restreints** : L'application est exécutée par un utilisateur non-root pour des raisons de sécurité.

### 2. Registre Docker Hub
L'image est construite (build) et poussée (push) automatiquement vers Docker Hub à chaque modification détectée par la pipeline CI/CD.

---

## Partie 3 : Déploiement sur Kubernetes

Le déploiement utilise les fonctionnalités natives de Kubernetes pour assurer la haute disponibilité, la persistance des données et la sécurité réseau.

### 1. Base de données MySQL
* **Persistance** : Mise en place d'un `PersistentVolumeClaim` (PVC) garantissant que les données de la base de données soient persistantes même lors du redémarrage du pod.
* **Initialisation** : Injection automatisée du schéma SQL via une `ConfigMap` montée au démarrage.
* **Isolation (Sécurité)** : Service configuré pour que l'API et la BDD soient joignables depuis l'intérieur du cluster uniquement, bloquant les accès externes.

### 2. API Node.js (Résilience et Scalabilité)
* **Auto-scaling** : Afin de garantir un fonctionnement fluide, un `HorizontalPodAutoscaler` (HPA) maintient au moins 1 pod en permanence et scale jusqu'à 3 pods en cas de pic de charge (consommation CPU/Mémoire élevée).
* **Self-healing** : Kubernetes gère le cycle de vie des pods, garantissant le redémarrage automatique en cas de défaillance.

---

## Partie 4 : Pipeline CI/CD

La pipeline GitHub Actions est le chef d'orchestre du projet. L'ensemble du processus de déploiement est exécuté dès que la branche `main` est modifiée. Elle s'exécute sur un **runner self-hosted** et enchaîne les étapes suivantes :

1. **Configuration de l'infrastructure** : Exécution de Terraform pour provisionner les VMs et création de l'inventaire Ansible.
2. **Build de l'image** : Création de l'image Docker optimisée.
3. **Déploiement sur l'infrastructure** : Push de l'image sur Docker Hub, déploiement des manifestes Kubernetes, et configuration du cluster.

---

## Partie 5 : Monitoring et Observabilité

L'infrastructure intègre une stack de supervision complète, déployée de façon 100% automatisée (Idempotence) via Ansible lors de l'exécution de la pipeline CI/CD.

### 1. Composants déployés
* **Nouvelle VM** : Provisionnement d'une VM dédiée sur laquelle sont installés Grafana et Prometheus.
* **Node Exporter** : Installation de `prometheus/node_exporter` sur les deux VM (le nœud K3s et le serveur de Monitoring) pour remonter les métriques matérielles (CPU, RAM, Disque).

### 2. Configuration dynamique et Provisioning
* **Prometheus** : Le fichier `prometheus.yml` est templatisé par Ansible pour cibler automatiquement les adresses IP dynamiques des deux serveurs.