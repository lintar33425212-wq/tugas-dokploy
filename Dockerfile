FROM php:8.4-fpm-alpine

# Install kebutuhan sistem
RUN apk add --no-cache \
    nginx \
    supervisor \
    su-exec \
    nodejs \
    npm \
    bash \
    curl \
    git \
    unzip \
    libzip-dev \
    icu-dev

# Install ekstensi PHP untuk Laravel dan MySQL
COPY --from=mlocati/php-extension-installer:latest \
    /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
    bcmath \
    exif \
    gd \
    intl \
    mbstring \
    opcache \
    pcntl \
    pdo_mysql \
    zip

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Salin seluruh project Laravel
COPY . .

# Install dependency Laravel
RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --optimize-autoloader

# Build frontend jika tersedia
RUN if [ -f package.json ]; then \
      npm install && npm run build; \
    fi

# Salin konfigurasi server
COPY docker/nginx.conf /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p /run/nginx \
    && mkdir -p storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]