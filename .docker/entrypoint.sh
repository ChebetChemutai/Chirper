#!/bin/sh

# Start the PHP-FPM process in the background
php-fpm82

# Start the Nginx process in the foreground
nginx -g 'daemon off;'