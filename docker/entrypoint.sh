#!/bin/sh
set -e

cd /var/www/html

# Siapkan folder yang dibutuhkan Laravel
mkdir -p \
    storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache

# Berikan izin akses ke folder Laravel
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Pastikan APP_KEY tersedia
if [ -z "$APP_KEY" ]; then
    echo "ERROR: APP_KEY belum diatur."
    exit 1
fi

# Tunggu database siap
if [ "$DB_CONNECTION" = "mysql" ]; then
    echo "Menunggu koneksi database..."

    until php -r '
        try {
            new PDO(
                "mysql:host=" . getenv("DB_HOST") .
                ";port=" . (getenv("DB_PORT") ?: "3306"),
                getenv("DB_USERNAME"),
                getenv("DB_PASSWORD")
            );
        } catch (Exception $e) {
            exit(1);
        }
    '; do
        sleep 3
    done

    echo "Database siap."
fi

# Jalankan migrasi database
php artisan migrate --force

# Jalankan PHP-FPM dan Nginx melalui Supervisor
exec /usr/bin/supervisord -c /etc/supervisord.conf