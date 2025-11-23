# --- STAGE 1 : build Angular ---
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Build navigateur, sans prerender/SSR
RUN npx ng build tryp-frontend --configuration production --prerender=false

# --- STAGE 2 : nginx ---
FROM nginx:1.27-alpine

# On enlève la conf par défaut
RUN rm /etc/nginx/conf.d/default.conf

# On met la nôtre
COPY nginx.conf /etc/nginx/conf.d/default.conf

# ⚠️ ICI : on copie bien le dossier browser !
COPY --from=build /app/dist/tryp-frontend/browser /usr/share/nginx/html

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
