#https://www.cloudsigma.com/deploying-laravel-nginx-and-mysql-with-docker-compose/
FROM php:8.2-fpm

# Copy composer.lock and composer.json into the working directory
COPY composer.lock composer.json /var/www/html/

# Set working directory
WORKDIR /var/www/html/

# Install dependencies for the operating system software
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    libzip-dev \
    unzip \
    git \
    libonig-dev \
    curl

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install extensions for php
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install gd

# Install composer (php package manager)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy existing application directory contents to the working directory
COPY . /var/www/html

# Assign permissions of the working directory to th e www-data user
RUN chown -R www-data:www-data \
    /var/www/html/storage \
    /var/www/html/bootstrap/cache

# Add xdebug
RUN pecl install xdebug-3.2.2
RUN docker-php-ext-enable xdebug
RUN docker-php-ext-install sockets

# Configure Xdebug
RUN echo "xdebug.client_host=192.168.12.120"        >> /usr/local/etc/php/conf.d/xdebug.ini \
    #&& echo "xdebug.remote_enable=1"               >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.client_port=9000"               >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.start_with_request=yes"         >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.force_display_errors=1"         >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_handler=dbgp"            >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.mode=develop,debug,coverage"    >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.discover_client_host=0"         >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.log=/tmp/xdebug.log"            >> /usr/local/etc/php/conf.d/xdebug.ini

RUN chown -R www-data:www-data /tmp

RUN composer install
#COPY .env.example .env
#RUN php artisan key:generate

#RUN composer require laravel/octane spiral/roadrunner-cli spiral/roadrunner-http
RUN php artisan octane:install --server="roadrunner"
RUN chmod +x ./vendor/bin/rr
RUN ./vendor/bin/rr get-binary
#RUN php artisan octane:start --server="roadrunner" --host="0.0.0.0" --rpc-port="6001" --port="80"

#RUN pecl install swoole
#RUN php artisan octane:install --server="swoole"



#RUN php artisan octane:start --server="swoole" --host="0.0.0.0" 

# Expose port 9000 and start php-fpm server (for FastCGI Process Manager)
EXPOSE 9000
CMD ["php-fpm"]