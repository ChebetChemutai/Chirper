# Dockerfile (Updated Version)

# Stage 1: The "builder" stage
FROM composer:2 as builder
WORKDIR /app
COPY database/ database/
COPY composer.json composer.lock ./
RUN composer install --no-interaction --no-plugins --no-scripts --prefer-dist --no-dev --optimize-autoloader
COPY . .
RUN composer dump-autoload --optimize
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache


# Stage 2: The "final" production stage
FROM nginx:1.25-alpine
WORKDIR /var/www/html

# Install PHP and required extensions
RUN apk add --no-cache php82 php82-fpm php82-pgsql php82-pdo php82-pdo_pgsql php82-tokenizer php82-xml php82-ctype php82-session php82-dom php82-fileinfo php82-openssl

# Copy app files from the "builder" stage
COPY --from=builder /app .

# Copy Nginx and PHP-FPM configurations
COPY .docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY .docker/php/www.conf /etc/php82/php-fpm.d/www.conf

# Copy the startup script
COPY .docker/entrypoint.sh .docker/entrypoint.sh

# Set correct permissions
RUN chown -R nginx:nginx /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod +x .docker/entrypoint.sh

# Expose port 80
EXPOSE 80

# The command to start the server
CMD ["/var/www/html/.docker/entrypoint.sh"]