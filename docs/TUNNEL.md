# Cloudflare Tunnel Setup Guide

Complete guide for creating, managing, and troubleshooting Cloudflare tunnels using `cloudflared`.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Creating a New Tunnel](#creating-a-new-tunnel)
- [Configuring Tunnels](#configuring-tunnels)
- [Systemd Service Setup](#systemd-service-setup)
- [Credentials Management](#credentials-management)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Reference](#reference)

---

## Overview

Cloudflare Tunnel (formerly Argo Tunnel) allows you to expose local services to the internet without opening inbound firewall ports. All traffic routes through Cloudflare's network to your origin server.

**Key Components:**
- **Tunnel**: A secure connection between your server and Cloudflare
- **Credentials**: JSON file containing tunnel authentication (AccountTag, TunnelID, TunnelSecret)
- **Config**: YAML file defining ingress rules (hostname → local service mapping)
- **Systemd Service**: Background daemon to keep tunnel running

---

## Prerequisites

### 1. Install cloudflared

```bash
# Arch Linux
sudo pacman -S cloudflared

# Ubuntu/Debian
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb

# Manual install
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
sudo install -m 755 cloudflared /usr/bin/cloudflared
```

### 2. Authenticate with Cloudflare

```bash
cloudflared tunnel login
```

This opens a browser to authenticate and downloads a certificate to `~/.cloudflared/cert.pem`.

**Location:** `~/.cloudflared/cert.pem` (required for all tunnel operations)

### 3. Verify Authentication

```bash
cloudflared tunnel list
```

Should show existing tunnels in your Cloudflare account.

---

## Creating a New Tunnel

### Step 1: Create the Tunnel

```bash
# Syntax: cloudflared tunnel create <tunnel-name>
cloudflared tunnel create onepunch-dev
```

**Output:**
```
Tunnel credentials written to /home/user/.cloudflared/334f70a8-0e05-4fbf-a1b5-9aa8a5c5fe3d.json
Created tunnel onepunch-dev with id 334f70a8-0e05-4fbf-a1b5-9aa8a5c5fe3d
```

**Important:** Save the tunnel ID! You'll need it later.

### Step 2: Create Project Directory Structure

```bash
# In your project directory
mkdir -p .cloudflared
```

### Step 3: Generate Credentials File

**Method 1: Using cloudflared CLI (Recommended)**

```bash
# Syntax: cloudflared tunnel token --cred-file <path> <tunnel-id>
cloudflared tunnel token \
  --cred-file /projects/onepunch/web/.cloudflared/credentials.json \
  334f70a8-0e05-4fbf-a1b5-9aa8a5c5fe3d
```

This creates a properly formatted credentials file:
```json
{
  "AccountTag": "188d57fbca9d0234d5a5bd7a76344b9b",
  "TunnelSecret": "NWU2NWY3OWEtNzYxNS00MTNlLTkxZjMtNDIwYjRiMjMyYzk3",
  "TunnelID": "334f70a8-0e05-4fbf-a1b5-9aa8a5c5fe3d",
  "Endpoint": ""
}
```

**Method 2: Copy from ~/.cloudflared**

```bash
# Copy the auto-generated file
cp ~/.cloudflared/334f70a8-0e05-4fbf-a1b5-9aa8a5c5fe3d.json \
   .cloudflared/credentials.json
```

**Security:**
```bash
# Set proper permissions (read-only for owner)
chmod 400 .cloudflared/credentials.json
```

### Step 4: Create Configuration File

Create `.cloudflared/config.yml`:

```yaml
tunnel: onepunch-dev
credentials-file: .cloudflared/credentials.json

ingress:
  - hostname: dev.onepunch.work
    service: http://localhost:2030
  - service: http_status:404  # Catch-all rule (required)
```

**Ingress Rules:**
- First matching rule wins
- Last rule must be a catch-all (no hostname)
- Service formats:
  - `http://localhost:3000` - HTTP service
  - `https://localhost:8443` - HTTPS service
  - `tcp://localhost:5432` - TCP service
  - `http_status:404` - Return 404

### Step 5: Configure DNS

```bash
# Route DNS to tunnel
cloudflared tunnel route dns onepunch-dev dev.onepunch.work
```

Or manually in Cloudflare dashboard:
1. Go to DNS settings
2. Add CNAME record:
   - **Name:** `dev`
   - **Target:** `<tunnel-id>.cfargotunnel.com`
   - **Proxy:** Enabled (orange cloud)

### Step 6: Test the Tunnel

```bash
# Run in foreground for testing
cloudflared tunnel --config .cloudflared/config.yml run
```

**Expected output:**
```
INF Starting tunnel tunnelID=334f70a8-0e05-4fbf-a1b5-9aa8a5c5fe3d
INF Registered tunnel connection connIndex=0 location=bkk01 protocol=quic
INF Registered tunnel connection connIndex=1 location=sin11 protocol=quic
```

Test in another terminal:
```bash
curl https://dev.onepunch.work
```

Stop the test: `Ctrl+C`

---

## Configuring Tunnels

### Multiple Hostnames (Single Service)

```yaml
tunnel: my-tunnel
credentials-file: .cloudflared/credentials.json

ingress:
  - hostname: app.example.com
    service: http://localhost:3000
  - hostname: api.example.com
    service: http://localhost:3000
  - service: http_status:404
```

### Multiple Services

```yaml
tunnel: my-tunnel
credentials-file: .cloudflared/credentials.json

ingress:
  - hostname: app.example.com
    service: http://localhost:3000
  - hostname: api.example.com
    service: http://localhost:4000
  - hostname: admin.example.com
    service: http://localhost:5000
  - service: http_status:404
```

### Path-Based Routing

```yaml
tunnel: my-tunnel
credentials-file: .cloudflared/credentials.json

ingress:
  - hostname: example.com
    path: /api/*
    service: http://localhost:4000
  - hostname: example.com
    service: http://localhost:3000
  - service: http_status:404
```

### Advanced Options

```yaml
tunnel: my-tunnel
credentials-file: .cloudflared/credentials.json

ingress:
  - hostname: app.example.com
    service: http://localhost:3000
    originRequest:
      noTLSVerify: true           # Skip TLS verification
      connectTimeout: 30s         # Connection timeout
      keepAliveTimeout: 90s       # Keep-alive timeout
      httpHostHeader: internal.local  # Override Host header
  - service: http_status:404
```

---

## Systemd Service Setup

### Create Service File

**File:** `/etc/systemd/system/cloudflared-<project>.service`

```ini
[Unit]
Description=cloudflared-<project>
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
TimeoutStartSec=0
RestartSec=60
WorkingDirectory=/projects/<project>/web
ExecStart=/usr/bin/cloudflared tunnel --config /projects/<project>/web/.cloudflared/config.yml run
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Example: OnePunch Service

**File:** `/etc/systemd/system/cloudflared-onepunch.service`

```ini
[Unit]
Description=cloudflared-onepunch
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
TimeoutStartSec=0
RestartSec=60
WorkingDirectory=/projects/onepunch/web
ExecStart=/usr/bin/cloudflared tunnel --config /projects/onepunch/web/.cloudflared/config.yml run
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Example: Zorp Service

**File:** `/etc/systemd/system/cloudflared-zorp.service`

```ini
[Unit]
Description=cloudflared-zorp-tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
TimeoutStartSec=0
RestartSec=60
WorkingDirectory=/projects/zorp
ExecStart=/usr/bin/cloudflared tunnel --config /projects/zorp/.cloudflared/config.yml run
Restart=on-failure
RestartSec=30s

[Install]
WantedBy=multi-user.target
```

### Service Management

```bash
# Reload systemd after creating/editing service
sudo systemctl daemon-reload

# Start tunnel
sudo systemctl start cloudflared-onepunch.service

# Stop tunnel
sudo systemctl stop cloudflared-onepunch.service

# Restart tunnel
sudo systemctl restart cloudflared-onepunch.service

# Enable on boot
sudo systemctl enable cloudflared-onepunch.service

# Disable on boot
sudo systemctl disable cloudflared-onepunch.service

# Check status
sudo systemctl status cloudflared-onepunch.service

# View logs
sudo journalctl -u cloudflared-onepunch.service -f

# View last 100 lines
sudo journalctl -u cloudflared-onepunch.service -n 100
```

---

## Credentials Management

### Understanding credentials.json

The credentials file contains four fields:

```json
{
  "AccountTag": "188d57fbca9d0234d5a5bd7a76344b9b",    // Your Cloudflare account ID
  "TunnelSecret": "NWU2NWY3OWEtNzYxNS...",           // Tunnel authentication secret
  "TunnelID": "334f70a8-0e05-4fbf-a1b5-9aa8a5c5fe3d", // Unique tunnel identifier
  "Endpoint": ""                                      // Usually empty
}
```

**Security Notes:**
- **TunnelSecret** is the most sensitive field
- Treat this file like a password
- Never commit to git (add to `.gitignore`)
- Set permissions to `400` (read-only for owner)

### Regenerating Lost Credentials

If you lose your credentials file but have the tunnel ID:

```bash
# Method 1: Using tunnel token command
cloudflared tunnel token \
  --cred-file /projects/onepunch/web/.cloudflared/credentials.json \
  334f70a8-0e05-4fbf-a1b5-9aa8a5c5fe3d
```

**Note:** The file must not exist. Backup first if needed:
```bash
mv .cloudflared/credentials.json .cloudflared/credentials.json.backup
```

### Finding Your Tunnel ID

```bash
# List all tunnels
cloudflared tunnel list

# Output shows ID, name, creation date, and connections
# ID                                   NAME            CREATED              CONNECTIONS
# 334f70a8-0e05-4fbf-a1b5-9aa8a5c5fe3d onepunch-dev-01 2025-10-08T00:01:31Z 2xbkk01, 1xsin02
```

### Extracting from Tunnel Token

If you have an old tunnel token (JWT format):

```bash
# Decode the base64 token
echo "eyJhIjoiMTg4ZD..." | base64 -d | jq .

# Output:
# {
#   "a": "188d57fbca9d0234d5a5bd7a76344b9b",  // AccountTag
#   "t": "334f70a8-0e05-4fbf-a1b5-9aa8a5c5fe3d",  // TunnelID
#   "s": "NWU2NWY3OWEtNzYxNS00MTNlLTkxZjMtNDIwYjRiMjMyYzk3"  // TunnelSecret (base64)
# }
```

**Then recreate credentials.json:**
```json
{
  "AccountTag": "<value from 'a'>",
  "TunnelSecret": "<value from 's'>",
  "TunnelID": "<value from 't'>",
  "Endpoint": ""
}
```

**Security Warning:** Never store tunnel tokens in systemd service files! Use credentials files instead.

### .gitignore Configuration

Always ignore credentials:

```gitignore
# Cloudflare Tunnel credentials
.cloudflared/credentials.json
.cloudflared/*.json
!.cloudflared/credentials.json.example
```

### Credentials Template

Create `.cloudflared/credentials.json.example`:

```json
{
  "AccountTag": "your-account-id-here",
  "TunnelID": "your-tunnel-id-here",
  "TunnelSecret": "your-tunnel-secret-here",
  "Endpoint": ""
}
```

---

## Troubleshooting

### Check Tunnel Status

```bash
# List tunnels and their connections
cloudflared tunnel list

# Get detailed info for specific tunnel
cloudflared tunnel info <tunnel-id>
cloudflared tunnel info 334f70a8-0e05-4fbf-a1b5-9aa8a5c5fe3d
```

### Common Issues

#### 1. "Invalid client_id" or Authentication Errors

**Cause:** Missing or incorrect credentials file

**Solution:**
```bash
# Regenerate credentials
cloudflared tunnel token \
  --cred-file .cloudflared/credentials.json \
  <tunnel-id>
```

#### 2. "Tunnel not found"

**Cause:** Tunnel was deleted or credentials don't match

**Solution:**
```bash
# Verify tunnel exists
cloudflared tunnel list | grep <tunnel-name>

# If missing, create new tunnel
cloudflared tunnel create <tunnel-name>
```

#### 3. "Failed to serve tunnel connection"

**Cause:** Network connectivity issues or Cloudflare API problems

**Solution:**
- Check internet connection
- Wait a few minutes and retry (temporary API issues)
- Check Cloudflare status: https://www.cloudflarestatus.com/

#### 4. 502 Bad Gateway

**Cause:** Local service is not running

**Solution:**
```bash
# Check if your local service is running
curl http://localhost:2030

# Start your application
./bin/dev  # or your start command
```

#### 5. Tunnel Starts But No Connections

**Check config file syntax:**
```bash
# Validate YAML syntax
cloudflared tunnel ingress validate

# Or test config manually
cloudflared tunnel --config .cloudflared/config.yml ingress validate
```

**Common config errors:**
- Missing catch-all rule (last ingress entry must have no hostname)
- Wrong indentation in YAML
- Invalid service URL format

#### 6. Permission Denied on credentials.json

**Cause:** File permissions too restrictive for cloudflared to read

**Solution:**
```bash
# Make readable by owner
chmod 400 .cloudflared/credentials.json

# Verify ownership
ls -la .cloudflared/credentials.json

# Should show: -r-------- 1 user user
```

### Debugging Commands

```bash
# Test tunnel in foreground with verbose logging
cloudflared tunnel --loglevel debug --config .cloudflared/config.yml run

# Test ingress rules
cloudflared tunnel ingress rule https://dev.onepunch.work
# Output: Using rule 0: dev.onepunch.work -> http://localhost:2030

# Check systemd service logs
sudo journalctl -u cloudflared-onepunch.service -f --since "5 minutes ago"

# Check connections to Cloudflare edge
cloudflared tunnel list
# Look for CONNECTIONS column: "2xbkk01, 1xsin02" means 3 active connections
```

### Network Diagnostics

```bash
# Test DNS resolution
dig dev.onepunch.work
# Should resolve to Cloudflare IP (CNAME to *.cfargotunnel.com)

# Test HTTPS endpoint
curl -v https://dev.onepunch.work

# Test with specific headers
curl -H "Host: dev.onepunch.work" https://dev.onepunch.work

# Check local service directly
curl http://localhost:2030
```

---

## Best Practices

### 1. Security

- **Never commit credentials to git**
  ```gitignore
  .cloudflared/credentials.json
  ```

- **Use credentials file instead of token in systemd**
  ```ini
  # ✓ Good: Uses credentials file
  ExecStart=/usr/bin/cloudflared tunnel --config /path/to/config.yml run

  # ✗ Bad: Token exposed in service file
  ExecStart=/usr/bin/cloudflared tunnel run --token eyJhIjoiMTg4ZD...
  ```

- **Set proper file permissions**
  ```bash
  chmod 400 .cloudflared/credentials.json
  chmod 644 .cloudflared/config.yml
  ```

- **Use separate tunnels per environment**
  - `onepunch-dev` for development
  - `onepunch-staging` for staging
  - `onepunch-prod` for production

### 2. Reliability

- **Enable systemd service on boot**
  ```bash
  sudo systemctl enable cloudflared-onepunch.service
  ```

- **Set proper restart policy**
  ```ini
  Restart=on-failure
  RestartSec=60
  ```

- **Monitor tunnel health**
  ```bash
  # Set up monitoring alert when connections = 0
  cloudflared tunnel list | grep onepunch-dev
  ```

### 3. Configuration Management

- **Use relative paths in config.yml**
  ```yaml
  # ✓ Good: Relative to config file location
  credentials-file: .cloudflared/credentials.json

  # ✗ Bad: Absolute path (not portable)
  credentials-file: /projects/onepunch/web/.cloudflared/credentials.json
  ```

- **Set WorkingDirectory in systemd**
  ```ini
  WorkingDirectory=/projects/onepunch/web
  ```

- **Document tunnel purpose in config**
  ```yaml
  # OnePunch Development Tunnel
  # Routes dev.onepunch.work -> localhost:2030 (Rails API)
  tunnel: onepunch-dev
  credentials-file: .cloudflared/credentials.json
  # ...
  ```

### 4. Testing

- **Always test in foreground first**
  ```bash
  # Test before creating systemd service
  cloudflared tunnel --config .cloudflared/config.yml run
  ```

- **Validate ingress rules**
  ```bash
  cloudflared tunnel ingress validate
  cloudflared tunnel ingress rule https://dev.onepunch.work
  ```

- **Check all endpoints**
  ```bash
  curl https://dev.onepunch.work/api/v1/health
  ```

### 5. Maintenance

- **Keep cloudflared updated**
  ```bash
  # Check version
  cloudflared --version

  # Update (Arch Linux)
  sudo pacman -Syu cloudflared
  ```

- **Monitor logs regularly**
  ```bash
  sudo journalctl -u cloudflared-onepunch.service --since yesterday
  ```

- **Backup credentials**
  ```bash
  # Encrypted backup
  gpg -c .cloudflared/credentials.json
  # Store credentials.json.gpg securely
  ```

---

## Reference

### File Structure

```
/projects/onepunch/web/
├── .cloudflared/
│   ├── config.yml                    # Tunnel configuration
│   ├── credentials.json              # Tunnel credentials (gitignored)
│   └── credentials.json.example      # Template for credentials
└── ...

/etc/systemd/system/
└── cloudflared-onepunch.service      # Systemd service file
```

### Essential Commands

```bash
# Authentication
cloudflared tunnel login

# Tunnel Management
cloudflared tunnel create <name>
cloudflared tunnel list
cloudflared tunnel info <id>
cloudflared tunnel delete <id>

# Credentials
cloudflared tunnel token --cred-file <path> <tunnel-id>

# DNS Routing
cloudflared tunnel route dns <tunnel> <hostname>
cloudflared tunnel route ip add <ip-range> <tunnel>  # For private networks

# Testing
cloudflared tunnel --config <path> run
cloudflared tunnel ingress validate
cloudflared tunnel ingress rule <url>

# Systemd
sudo systemctl daemon-reload
sudo systemctl start cloudflared-<project>
sudo systemctl status cloudflared-<project>
sudo systemctl enable cloudflared-<project>
sudo journalctl -u cloudflared-<project> -f
```

### Configuration Examples

**Working Tunnels:**

| Tunnel | ID | Hostname | Service | Config |
|--------|----|----|---------|--------|
| onepunch-dev-01 | `334f70a8-0e05-4fbf-a1b5-9aa8a5c5fe3d` | dev.onepunch.work | http://localhost:2030 | `/projects/onepunch/web/.cloudflared/` |
| zorp-dev | `7ae979e2-13d9-4dcb-b3b8-dbcedf278cec` | zorp-dev.onepunch.work | http://localhost:3009 | `/projects/zorp/.cloudflared/` |
| dev-trader | `2f205d9c-f57d-4145-920d-3bbed6f8b056` | dev-trader.onepunch.work | http://localhost:3001 | `/projects/trader/.cloudflared/` |

### Useful Links

- **Official Documentation:** https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **GitHub Releases:** https://github.com/cloudflare/cloudflared/releases
- **Cloudflare Status:** https://www.cloudflarestatus.com/
- **Zero Trust Dashboard:** https://one.dash.cloudflare.com/

---

## Quick Reference: OnePunch Setup

### Current Configuration

**Tunnel Name:** `onepunch-dev-01`
**Tunnel ID:** `334f70a8-0e05-4fbf-a1b5-9aa8a5c5fe3d`
**Account ID:** `188d57fbca9d0234d5a5bd7a76344b9b`
**Hostname:** `dev.onepunch.work`
**Local Service:** `http://localhost:2030` (Rails API)

### Files

```bash
# Credentials
/projects/onepunch/web/.cloudflared/credentials.json

# Config
/projects/onepunch/web/.cloudflared/config.yml

# Systemd service
/etc/systemd/system/cloudflared-onepunch.service
```

### Common Tasks

```bash
# Start tunnel
sudo systemctl start cloudflared-onepunch.service

# Check status
sudo systemctl status cloudflared-onepunch.service

# View logs
sudo journalctl -u cloudflared-onepunch.service -f

# Restart after config change
sudo systemctl restart cloudflared-onepunch.service

# Test endpoint
curl https://dev.onepunch.work
```

---

**Last Updated:** 2025-10-18
**Maintainer:** OnePunch Team
