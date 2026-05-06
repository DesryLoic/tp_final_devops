# 1. Builder
FROM node:18-alpine AS builder
WORKDIR /app
# On copie d'abord uniquement les fichiers de configuration npm. 
COPY package*.json ./
# Installation des bibliothèque nécessaire
RUN npm install
# Puis copie du reste du code source
COPY . .

# 2. Production
FROM node:18-alpine
WORKDIR /app

# Permet d'ignorer les outils de developpeur (pour l'automatisation)
ENV NODE_ENV=production

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY --from=builder /app/config ./config
COPY --from=builder /app/package.json ./package.json

# Lancement avec un utilisateur standard et non avec un role d'admin (passage de root à node)
USER node

# On indique sur quel port l'application écoute en interne
EXPOSE 3000

# La commande finale pour démarrer l'API
CMD ["npm", "start"]
