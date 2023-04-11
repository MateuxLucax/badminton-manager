# Observação. Este arquivo deve estar na raiz do projeto. E serve apenas para ambiente de desenvolvimento.

# Imagem base oficial do PHP 8.1 com Apache
FROM php:8.1-apache

# Atualiza os pacotes e instala as dependências necessárias
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y git zip unzip libpq-dev \
    && docker-php-ext-install pdo_pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Habilita o mod_rewrite do Apache
RUN a2enmod rewrite

# Configura o 'ServerName' no arquivo de configuração do Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Instala o Xdebug e habilita-o
RUN pecl install xdebug && docker-php-ext-enable xdebug

# Configura o Xdebug
COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Desativa o Xdebug temporariamente
RUN sed -i 's/xdebug.mode=debug/xdebug.mode=off/g' /usr/local/etc/php/conf.d/xdebug.ini

# Copia os arquivos do projeto para o container
COPY . /var/www/html

# Instala o Composer globalmente
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Cria um novo usuário 'composeruser'
RUN useradd --create-home --shell /bin/bash composeruser

# Muda para o usuário 'composeruser'
USER composeruser

# Define o diretório de trabalho
WORKDIR /var/www/html

# Instala as dependências do projeto usando o Composer
RUN composer install --no-interaction

# Volta para o usuário root
USER root

# Reativa o Xdebug
RUN sed -i 's/xdebug.mode=off/xdebug.mode=debug/g' /usr/local/etc/php/conf.d/xdebug.ini

# Define a pasta /var/www como a raiz do Apache
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

# Altera o DocumentRoot do Apache
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# Expõe a porta 80 para acesso externo
EXPOSE 80
