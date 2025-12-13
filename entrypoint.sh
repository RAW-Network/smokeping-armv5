#!/bin/bash
set -e

# Configuration Paths
CONFIG_SRC="/defaults"
CONFIG_DST="/config"
CONFIG_LINK="/etc/smokeping"
DATA_DIR="/data"
CACHE_DIR="/var/cache/smokeping"
WEB_DIR="/usr/share/smokeping/www"

# Logging
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"
}

# Directory Setup
log_info "Verifying runtime directories..."
mkdir -p "$CONFIG_DST" "$DATA_DIR" "$CACHE_DIR" /var/run/smokeping /var/log/smokeping

# Config Initialization
if [ ! -f "$CONFIG_DST/config" ]; then
    log_info "Config volume is empty, Initializing defaults..."
    cp -a "$CONFIG_SRC/." "$CONFIG_DST/"
    chown -R www-data:www-data "$CONFIG_DST"
    log_info "Default configuration populated"
else
    log_info "Existing configuration found, Skipping initialization"
fi

# Symlink System Config
if [ -d "$CONFIG_LINK" ] && [ ! -L "$CONFIG_LINK" ]; then
    rm -rf "$CONFIG_LINK"
fi
if [ ! -L "$CONFIG_LINK" ]; then
    ln -s "$CONFIG_DST" "$CONFIG_LINK"
    log_info "Linked system config: $CONFIG_LINK -> $CONFIG_DST"
fi

# Image Cache
if [ ! -L "$WEB_DIR/cache" ]; then
    rm -rf "$WEB_DIR/cache"
    ln -s "$CACHE_DIR" "$WEB_DIR/cache"
    log_info "Linked image cache: $WEB_DIR/cache -> $CACHE_DIR"
fi

# Permissions & Cleanup
chown -R www-data:www-data "$DATA_DIR" "$CACHE_DIR" "$WEB_DIR" /var/run/smokeping /var/log/smokeping
rm -f /var/run/smokeping/smokeping.pid /var/run/apache2/apache2.pid 2>/dev/null || true

# Start Services
log_info "Starting Smokeping Daemon..."
/usr/sbin/smokeping \
    --config="$CONFIG_LINK/config" \
    --logfile="/var/log/smokeping/smokeping.log" \
    > /var/log/smokeping/smokeping-stdout.log 2>&1 &

echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf
a2enconf servername >/dev/null 2>&1 || true

log_info "Starting Apache Web Interface..."
log_info "Smokeping is ready!"
exec /usr/sbin/apachectl -D FOREGROUND