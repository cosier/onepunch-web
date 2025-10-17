#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Simple Mustache-like template renderer
function renderTemplate(template, data) {
  return template.replace(/\{\{([^}]+)\}\}/g, (match, key) => {
    const trimmedKey = key.trim();
    return data[trimmedKey] !== undefined ? data[trimmedKey] : match;
  });
}

// Get environment from command line or use default
const environment = process.env.RAILS_ENV || 'development';
console.log(`Generating Nginx configs for environment: ${environment}`);

// Define template variables based on environment
const templateData = {
  environment,
  // Use local domains for development/test, production domains for production
  appDomain: process.env.APP_DOMAIN || 
              (environment === 'production' ? 'autoboost.social-ads.fr' : 'local.autoboost.social-ads.fr'),
  frontendPort: process.env.FRONTEND_CONTAINER_PORT || process.env.WORKSPACE_FRONTEND_PORT || '3000',
  apiPort: process.env.API_CONTAINER_PORT || process.env.WORKSPACE_API_PORT || '3000',
  astralPort: process.env.WORKSPACE_ASTRAL_PORT || '3000',
  sslCertPath: process.env.SSL_CERT_PATH || '/etc/nginx/ssl/cert.pem',
  sslKeyPath: process.env.SSL_KEY_PATH || '/etc/nginx/ssl/key.pem'
};

console.log(`Using domains: Main=${templateData.appDomain}`);

// Ensure output directory exists
const outputDir = '/etc/nginx/conf.d';
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

// Template files to process - use consistent naming
const templateFiles = [
  { 
    src: path.join('/etc/nginx/templates', 'autoboost.conf.mustache'),
    dest: path.join(outputDir, `${templateData.appDomain}.conf`)
  }
];

// Process each template
templateFiles.forEach(({ src, dest }) => {
  try {
    if (!fs.existsSync(src)) {
      console.error(`Template file not found: ${src}`);
      return;
    }

    const template = fs.readFileSync(src, 'utf-8');
    const rendered = renderTemplate(template, templateData);
    
    fs.writeFileSync(dest, rendered);
    console.log(`Generated: ${dest}`);
  } catch (error) {
    console.error(`Error processing template ${src}:`, error);
  }
});

console.log('Nginx configuration generation completed.');

// Optional: Notify about the generated files
try {
  const configFiles = templateFiles.map(f => path.basename(f.dest)).join(', ');
  console.log(`Generated Nginx config files: ${configFiles}`);
  // show config contents
  const configContents = fs.readFileSync(templateFiles[0].dest, 'utf-8');
  console.log(configContents);
} catch (error) {
  console.error('Error listing generated files:', error);
} 
