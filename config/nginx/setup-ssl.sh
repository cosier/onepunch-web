#!/bin/bash

# Create directory for autoboost.social-ads.fr
mkdir -p /etc/nginx/ssl/autoboost.social-ads.fr

# Generate self-signed certificates for local development
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/autoboost.social-ads.fr/privkey.pem \
  -out /etc/nginx/ssl/autoboost.social-ads.fr/fullchain.pem \
  -subj "/CN=autoboost.social-ads.fr"

# Set appropriate permissions
chmod 600 /etc/nginx/ssl/autoboost.social-ads.fr/privkey.pem
chmod 644 /etc/nginx/ssl/autoboost.social-ads.fr/fullchain.pem

echo "SSL certificate setup complete for autoboost.social-ads.fr"