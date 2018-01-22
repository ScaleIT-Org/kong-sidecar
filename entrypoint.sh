#!/bin/sh
set -e

# Disabling nginx daemon mode
export KONG_NGINX_DAEMON="off"

# Setting default prefix (override any existing variable)
export KONG_PREFIX="/usr/local/kong"

# Prepare Kong prefix
if [ "$1" = "/usr/local/openresty/nginx/sbin/nginx" ]; then
	kong prepare -p "/usr/local/kong"
fi

echo "Preparing database..."
migrate=$(kong migrations up)
if [[ -z "${migrate// }" ]]; then
    echo "No migrations necessary"
else
    echo $migrate
    echo "Database preparation finished"
fi

if [ "$1" = "/usr/local/openresty/nginx/sbin/nginx" ]; then
    sh apply-config.sh &
fi
    
exec "$@"
