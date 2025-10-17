#!/bin/bash
set -e

# Get the environment from environment variable or default to development
ENV=${RAILS_ENV:-development}

echo "Starting Nginx in $ENV environment"

# Function to wait for a service to be available
wait_for_service() {
  local host="$1"
  local port="$2"
  local service_name="$3"
  local timeout="${4:-60}"
  
  echo "Waiting for $service_name service at $host:$port..."
  
  local start_time=$(date +%s)
  local end_time=$((start_time + timeout))
  
  while [ $(date +%s) -lt $end_time ]; do
    if nc -z "$host" "$port" > /dev/null 2>&1; then
      echo "$service_name is available!"
      return 0
    fi
    
    echo "Still waiting for $service_name at $host:$port... ($(($end_time - $(date +%s))) seconds left)"
    sleep 5
  done
  
  echo "Timeout reached waiting for $service_name. Starting Nginx anyway..."
  return 1
}

# Wait for frontend service
FRONTEND_HOST=${FRONTEND_HOST:-frontend}
FRONTEND_PORT=${FRONTEND_CONTAINER_PORT:-3000}
wait_for_service "$FRONTEND_HOST" "$FRONTEND_PORT" "Frontend" 120

# Remove the default nginx configuration to avoid conflicts
echo "Removing default nginx configuration..."
rm -f /etc/nginx/conf.d/default.conf

# Generate nginx configs based on environment
echo "Generating nginx configuration files..."
node /usr/local/bin/render-templates.js

# Start nginx
exec nginx -g "daemon off;"