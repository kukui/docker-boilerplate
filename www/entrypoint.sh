#!/bin/bash -e

# link certs
if [ "$SSL" == "1" ]; then
    if [ ! -f /etc/ssl/private/${DOMAIN}.crt ] ||
       [ ! -f /etc/ssl/private/${DOMAIN}.key ]; then
        echo "############################################################"
        echo "WARNING MISSING CERT AND/OR KEY: ${DOMAIN}.crt ${DOMAIN}.key"
        echo "############################################################"
        ls -lh /etc/ssl/private/
    fi
    to_link='00-default-ssl.conf 20-ssl-redirects.conf 30-static-and-api-ssl.conf'
else
    to_link='00-default.conf 30-static-and-api.conf'
fi

# remove any files from previous builds
rm -f /etc/nginx/sites-available/*.conf
rm -f /etc/nginx/sites-enabled/*

for file in /etc/nginx/sites-available/*.conf.var; do
    # replace occurences of the domain so that the appropriate certificate is linked
    (envsubst '$DOMAIN') < $file > /etc/nginx/sites-available/`basename $file .var`
done

# the files we link into sites-enabled depend on whether we're running SSL or not
for f in $to_link; do
    
    echo ln -sf /etc/nginx/sites-available/$f /etc/nginx/sites-enabled/$f
    ln -sf /etc/nginx/sites-available/$f /etc/nginx/sites-enabled/$f 

done

# start nginx
nginx -g "daemon off;"
