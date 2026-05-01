# Documentation - TP Final DevOps 


## Arborescence du projet

La structure a été pensée pour séparer strictement les responsabilités (Infrastructure, App, Orchestration) :

```text
tp_final_devops/
├── README.md               # Cette documentation
├── .github/
│   └── workflows/
│       └── deploy.yml      # Pipeline CI/CD GitHub Actions
├── Partie1/                # Infrastructure as Code (IaC)
│   ├── deploy.tf           # Configuration Terraform (VirtualBox)
│   └── get_ip.sh           # Script utilitaire de gestion d'IP
├── Partie2/                # Conteneurisation (Docker)
│   └── api-lacets/
│       ├── Dockerfile      # Build multi-stage optimisé
│       └── ...             # Code source Node.js
└── Partie3/                # Orchestration (Kubernetes)
    ├── api.yaml            # Manifeste API (HPA, Service, Deployment)
    └── mysql.yaml          # Manifeste Database (PVC, ConfigMap, Service)
```

---

## Partie 1 : Préparation de l'infrastructure

L'objectif est de passer d'un PC nu à un cluster Kubernetes prêt à l'emploi de manière 100% automatisée.

### 1. Provisionnement de la VM (Terraform)
Nous utilisons **Terraform** pour définir l'infrastructure. Le fichier `deploy.tf` configure une machine Debian sur VirtualBox avec 2 Go de RAM. L'utilisation de Terraform permet de garantir que l'environnement est reproductible à l'infini et que l'état de l'infrastructure est tracé.

### 2. Récupération dynamique de l'IP
La VM recevant une adresse IP via DHCP, la pipeline utilise les `outputs` de Terraform et le script `get_ip.sh` pour injecter l'IP réelle de la machine dans les variables d'environnement du Runner (`$GITHUB_ENV`). Cela permet à la pipeline de fonctionner de manière totalement agnostique vis-à-vis de l'adressage réseau de VirtualBox.

### 3. Installation de K3s (Connexion SSH Directe)
Pour garantir une fiabilité maximale en environnement CI/CD et éviter les conflits d'inventaires statiques, l'installation du cluster **K3s** est effectuée par une injection directe via SSH. 
* **Méthode :** Utilisation de `sshpass` pour une authentification automatisée sécurisée.
* **Exécution :** Installation via le script officiel `k3s.io`, permettant un déploiement rapide d'un cluster certifié CNCF sur une machine légère.

---

## Partie 2 : Conteneurisation de l'application

### 1. Optimisation du Dockerfile
Le `Dockerfile` de l'API Node.js suit les standards de production pour maximiser la sécurité et la performance :
* **Multi-stage build** : Permet de diviser la taille de l'image finale par 3 en ne conservant que le runtime nécessaire à l'exécution.
* **Image Alpine** : Utilisation de `node:18-alpine` pour limiter la surface d'attaque.
* **Privilèges restreints** : L'application est exécutée par l'utilisateur `node` (non-root).

### 2. Registre Docker Hub
L'image est buildée et poussée automatiquement vers Docker Hub à chaque modification du code source détectée par la pipeline.

---

## Partie 3 : Déploiement sur Kubernetes

Le déploiement utilise les fonctionnalités natives de Kubernetes pour assurer la haute disponibilité et la persistance.

### 1. Base de données MySQL
* **Persistance** : Mise en place d'un `PersistentVolumeClaim` (PVC) garantissant que les données clients sont conservées même si le pod MySQL est redémarré.
* **Initialisation** : Injection automatisée du schéma SQL (création des tables) via une `ConfigMap` montée au démarrage du conteneur.
* **Isolation** : Service de type `ClusterIP`, rendant la base de données invisible et inaccessible depuis l'extérieur du cluster.

### 2. API Node.js (Résilience et Scalabilité)
* **Auto-scaling** : Un `HorizontalPodAutoscaler` (HPA) surveille la consommation CPU et ajuste le nombre de répliques entre 1 et 3 pods en temps réel.
* **Self-healing** : Kubernetes gère automatiquement le cycle de vie des pods. Si la base de données n'est pas prête, le mécanisme de redémarrage automatique assure une stabilisation progressive du système.

---

## Partie 4 : Pipeline CI/CD

La pipeline est le chef d'orchestre du projet. Elle automatise le cycle complet à chaque `git push` :

1. **Phase IaC** : Initialisation et application de Terraform pour garantir l'état de la VM.
2. **Phase Setup** : Installation à la volée de Kubernetes sur la VM via SSH.
3. **Phase CI** : Build de l'image Docker optimisée et Push sur le registre public.
4. **Phase CD** : Déploiement des manifestes Kubernetes via SSH et mise à jour du cluster.
