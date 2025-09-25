# Dockerfile

# Use a multi-stage build to keep the final image small and secure
# Stage 1: The "builder" stage
FROM composer:2 as builder

# Set the working directory
WORKDIR /app

# Copy dependency files
COPY database/ database/
COPY composer.json composer.lock ./

# Install Composer dependencies
RUN composer install --no-interaction --no-plugins --no-scripts --prefer-dist --no-dev --optimize-autoloader

# Copy the rest of the application code
COPY . .

# Generate the autoloader again after copying the full app
RUN composer dump-autoload --optimize

# Generate Laravel caches for production
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache


# Stage 2: The "final" production stage
FROM nginx:1.25-alpine

# Set working directory
WORKDIR /var/www/html

# Install PHP and required extensions
RUN apk add --no-cache php82 php82-fpm php82-pgsql php82-pdo php82-pdo_pgsql php82-tokenizer php82-xml php82-ctype php82-session php82-dom php82-fileinfo php82-openssl

# Copy the application files from the "builder" stage
COPY --from=builder /app .

# Copy the Nginx configuration file
COPY .docker/nginx/default.conf /etc/nginx/conf.d/default.conf

# Set correct permissions for storage and bootstrap cache
RUN chown -R nginx:nginx /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Expose port 80 for the web server
EXPOSE 80

# The command to start the server
CMD ["nginx", "-g", "daemon off;"]