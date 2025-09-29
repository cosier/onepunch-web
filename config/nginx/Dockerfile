FROM nginx:latest

# Install Node.js for templating
RUN apt-get update && \
  apt-get install -y nodejs npm netcat-openbsd curl && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Copy render script and entrypoint
COPY ./render-templates.js /usr/local/bin/render-templates.js
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
COPY ./default.conf /etc/nginx/conf.d/default.conf.template

# Make scripts executable
RUN chmod +x /usr/local/bin/render-templates.js /usr/local/bin/entrypoint.sh

# Set working directory
WORKDIR /etc/nginx

# Command to run
CMD ["/bin/bash", "/usr/local/bin/entrypoint.sh"] 