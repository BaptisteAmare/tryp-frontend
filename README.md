# TrypFrontend

Application frontend Angular servie en production par **nginx** dans un conteneur **Docker**.

## 1. Prérequis

- **Node.js** v18+ (idéalement v20)
- **npm** v10+
- **Angular CLI** (global) :

```bash
npm install -g @angular/cli
````

* **Docker** installé et fonctionnel

---

## 2. Installation du projet

Cloner le repo et installer les dépendances :

```bash
git clone https://github.com/BaptisteAmare/tryp-frontend.git
cd tryp-frontend
npm install
```

---

## 3. Lancer l’application en local (dev)

### 3.1. Dev server Angular

Pour lancer l’application en mode développement :

```bash
ng serve
```

Par défaut, l’application sera disponible sur :

* [http://localhost:4200](http://localhost:4200)

> Tu peux ajouter `--open` pour ouvrir automatiquement le navigateur :
>
> ```bash
> ng serve --open
> ```

---

## 4. Build de l’application (production)

Pour générer un build de production (fichiers statiques dans `dist/`) :

```bash
ng build --configuration production --prerender=false
```

Les fichiers seront générés dans :

```text
dist/tryp-frontend/browser
```

Ce sont ces fichiers qui seront servis par **nginx** dans Docker.

---

## 5. Déploiement avec Docker + nginx

Le projet contient un `Dockerfile` qui :

1. Build l’application Angular (stage Node)
2. Copie les fichiers générés dans une image **nginx** (stage final)

### 5.1. Dockerfile (rappel)

Le `Dockerfile` ressemble à ceci :

```dockerfile
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Build navigateur uniquement (sans prerender/SSR)
RUN npx ng build tryp-frontend --configuration production --prerender=false

FROM nginx:1.27-alpine

RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# On copie le build Angular dans le dossier servi par nginx
COPY --from=build /app/dist/tryp-frontend/browser /usr/share/nginx/html

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
```

Et un `nginx.conf` minimal :

```nginx
server {
    listen 8080;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

---

### 5.2. Build de l’image Docker

Depuis la racine du projet :

```bash
docker build -t tryp-frontend-nginx .
```

---

### 5.3. Lancer le conteneur

Tu peux exposer le port **8080** interne de nginx sur un port externe de ton choix.

Exemple en exposant sur **9000** :

```bash
docker run -d --name tryp-frontend-nginx -p 9000:8080 tryp-frontend-nginx
```

L’application est alors disponible sur :

* [http://localhost:9000](http://localhost:9000)
* ou http://<ip-de-la-machine>:9000

Si tu veux utiliser directement le port 8080 en externe :

```bash
docker run -d --name tryp-frontend-nginx -p 8080:8080 tryp-frontend-nginx
```

→ [http://localhost:8080](http://localhost:8080)

---

## 6. Commandes utiles

Arrêter le conteneur :

```bash
docker stop tryp-frontend-nginx
```

Supprimer le conteneur :

```bash
docker rm tryp-frontend-nginx
```

Rebuild complet (sans cache) :

```bash
docker build --no-cache -t tryp-frontend-nginx .
```

---

## 7. Intégration derrière un reverse proxy (optionnel)

Si l’application est déployée derrière un reverse proxy (Nginx Proxy Manager, Traefik, etc.) :

* **Host / Container port** : `tryp-frontend-nginx:8080`
* Le reverse proxy peut ensuite exposer l’app via :

  * un sous-domaine (`app.mondomaine.com`)
  * ou un chemin (`mondomaine.com/app`)