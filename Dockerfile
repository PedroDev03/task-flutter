# Estágio 1: Baixar o Flutter e compilar a aplicação
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Copia todos os arquivos do projeto para o contêiner
COPY . .

# Baixa as dependências e gera os arquivos web
RUN flutter pub get
RUN flutter build web

# Estágio 2: Configurar o servidor web NGINX para rodar a aplicação
FROM nginx:alpine

# Copia a configuração do NGINX que criamos no passo anterior
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copia os arquivos compilados do Flutter para a pasta pública do NGINX
COPY --from=build /app/build/web /usr/share/nginx/html

# Expõe a porta 80 para a internet
EXPOSE 80

# Inicia o servidor
CMD ["nginx", "-g", "daemon off;"]