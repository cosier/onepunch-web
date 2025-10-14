# Rails Encrypted Credentials Guide

## Overview

OnePunch uses Rails encrypted credentials for secure secret management. This approach keeps all secrets encrypted in the repository, requiring only a single `RAILS_MASTER_KEY` for decryption.

## Why Encrypted Credentials?

**Traditional Approach (ENV vars):**
- ❌ 10+ separate environment variables to manage
- ❌ Risk of committing .env files to git
- ❌ No audit trail of secret changes
- ❌ Difficult to share secrets securely with team

**Encrypted Credentials Approach:**
- ✅ One key (RAILS_MASTER_KEY) decrypts everything
- ✅ Encrypted files committed to git (auditable history)
- ✅ No risk of leaking secrets
- ✅ Easy team sharing (share one key, not 10+ secrets)
- ✅ Environment-specific overrides (dev vs production)

## File Structure

```
config/
├── credentials.yml.enc           # Global credentials (fallback)
├── master.key                    # Global key (NOT in git)
└── credentials/
    ├── development.yml.enc       # Dev secrets (encrypted, IN git)
    ├── development.key           # Dev key (NOT in git)
    ├── production.yml.enc        # Prod secrets (encrypted, IN git)
    └── production.key            # Prod key (NOT in git)
```

**What's in Git:**
- ✅ `config/credentials/*.yml.enc` (encrypted files)
- ❌ `config/credentials/*.key` (decryption keys)
- ❌ `config/master.key` (master decryption key)

## Using the Credentials Script

### View Credentials (Read-Only)

```bash
# View development credentials
scripts/credentials.sh --environment development show

# View production credentials
scripts/credentials.sh --environment production show
```

Output:
```yaml
=== Credentials for development environment ===

# SMTP Configuration (AWS SES)
smtp:
  address: email-smtp.us-west-2.amazonaws.com
  port: 587
  user_name: AKIAVJ2C2RCPKIYUGKXA
  password: ...
  domain: onepunch.work

# Google OAuth
google:
  client_id: ...
  client_secret: ...
```

### Edit Credentials

```bash
# Edit development credentials (opens in $EDITOR)
export EDITOR=vim  # or code --wait, nano, etc.
scripts/credentials.sh --environment development edit

# Edit production credentials
scripts/credentials.sh --environment production edit
```

The script will:
1. Decrypt the credentials using the environment's key
2. Open them in your editor
3. Re-encrypt them when you save and close
4. Validate YAML syntax

### Dump Credentials (for AI/Automation)

```bash
# Dump as raw YAML (no headers)
scripts/credentials.sh --environment development dump

# Pipe to file
scripts/credentials.sh --environment development dump > backup.yml

# Send to AI for processing
scripts/credentials.sh --environment development dump | your-ai-tool
```

### Replace Credentials (from stdin)

Perfect for AI agents or automation:

```bash
# From file
cat new_credentials.yml | scripts/credentials.sh --environment development replace

# From AI output
echo "$AI_GENERATED_YAML" | scripts/credentials.sh --environment production replace

# Interactive
scripts/credentials.sh --environment development replace << 'EOF'
smtp:
  address: new-smtp.example.com
  port: 587
EOF
```

The replace command will:
1. Validate YAML syntax
2. Backup existing credentials (.yml.enc.backup)
3. Encrypt and save new credentials
4. Confirm success

## Credentials Format

### Structure

```yaml
# SMTP Configuration (AWS SES)
smtp:
  address: email-smtp.us-west-2.amazonaws.com
  port: 587
  user_name: YOUR_USERNAME
  password: YOUR_PASSWORD
  domain: onepunch.work

# Google OAuth
google:
  client_id: YOUR_CLIENT_ID.apps.googleusercontent.com
  client_secret: YOUR_CLIENT_SECRET

# Stripe
stripe:
  publishable_key: pk_test_... or pk_live_...
  secret_key: sk_test_... or sk_live_...

# AWS (if needed)
aws:
  access_key_id: YOUR_ACCESS_KEY
  secret_access_key: YOUR_SECRET_KEY
  region: us-west-2

# Custom secrets
api_keys:
  service_name: YOUR_API_KEY
```

### Naming Conventions

- Use nested structure: `service.setting`
- Use underscores for keys: `secret_key`, not `secretKey`
- Group related secrets under common parent
- Add comments for clarity

## Accessing Credentials in Code

### Ruby/Rails Code

```ruby
# Access credentials with dig
Rails.application.credentials.dig(:smtp, :address)
# => "email-smtp.us-west-2.amazonaws.com"

Rails.application.credentials.dig(:google, :client_id)
# => "830107058201-..."

# With fallback to ENV var
ENV["SMTP_ADDRESS"] || Rails.application.credentials.dig(:smtp, :address)

# Check if credential exists
if Rails.application.credentials.dig(:stripe, :secret_key)
  # Use Stripe
end
```

### Configuration Files

In `config/environments/production.rb`:

```ruby
config.action_mailer.smtp_settings = {
  address: ENV["SMTP_ADDRESS"] || Rails.application.credentials.dig(:smtp, :address),
  port: ENV["SMTP_PORT"] || Rails.application.credentials.dig(:smtp, :port),
  user_name: ENV["SMTP_USERNAME"] || Rails.application.credentials.dig(:smtp, :user_name),
  password: ENV["SMTP_PASSWORD"] || Rails.application.credentials.dig(:smtp, :password),
  domain: ENV["SMTP_DOMAIN"] || Rails.application.credentials.dig(:smtp, :domain),
  authentication: :plain,
  enable_starttls_auto: true
}
```

This pattern:
1. Tries ENV var first (backward compatibility)
2. Falls back to encrypted credentials
3. Allows gradual migration from ENV to credentials

## Deployment

### Kamal Configuration

In `config/deploy.yml`:

```yaml
env:
  secret:
    - RAILS_MASTER_KEY
    # That's it! All other secrets are in encrypted credentials
```

### Setting Up Production

1. **Generate production key** (already done):
   ```bash
   # Key is in config/credentials/production.key
   cat config/credentials/production.key
   # => c8993f9d8899d14d38a54140ba2c04be
   ```

2. **Update `.kamal/secrets`**:
   ```bash
   KAMAL_REGISTRY_PASSWORD=ghp_...
   RAILS_MASTER_KEY=c8993f9d8899d14d38a54140ba2c04be
   ```

3. **Deploy**:
   ```bash
   bin/deploy
   ```

Kamal will:
- Copy `config/credentials/production.yml.enc` to the server
- Set `RAILS_MASTER_KEY` environment variable
- Rails automatically decrypts credentials on boot

## Development Setup

### For New Team Members

1. **Clone the repository** (encrypted credentials already included)
   ```bash
   git clone https://github.com/yourorg/onepunch.git
   cd onepunch
   ```

2. **Get the development key** (share securely via 1Password, etc.)
   ```bash
   # Save to correct location
   echo "043907ca426b48a8a8411287ecfd2455" > config/credentials/development.key
   chmod 600 config/credentials/development.key
   ```

3. **Verify credentials work**
   ```bash
   scripts/credentials.sh --environment development show
   ```

4. **Update `.env.development`** with the key:
   ```bash
   RAILS_MASTER_KEY=043907ca426b48a8a8411287ecfd2455
   ```

That's it! No need to set 10+ environment variables.

## Adding New Secrets

### Step 1: Edit Credentials

```bash
scripts/credentials.sh --environment development edit
```

### Step 2: Add Your Secret

```yaml
# Add to the YAML file:
my_service:
  api_key: sk_test_12345
  api_secret: secret_67890
```

### Step 3: Update Code

```ruby
# Access in your code
MyService.configure do |config|
  config.api_key = Rails.application.credentials.dig(:my_service, :api_key)
  config.api_secret = Rails.application.credentials.dig(:my_service, :api_secret)
end
```

### Step 4: Update Production Credentials

```bash
scripts/credentials.sh --environment production edit
# Add the same structure with production values
```

### Step 5: Commit

```bash
git add config/credentials/*.yml.enc
git commit -m "Add MyService credentials"
```

The encrypted files are safe to commit!

## Security Best Practices

### DO ✅

- ✅ Commit encrypted `.yml.enc` files to git
- ✅ Keep `.key` files out of git (in .gitignore)
- ✅ Share keys via secure channels (1Password, encrypted email)
- ✅ Use environment-specific credentials (dev vs prod)
- ✅ Backup your keys securely
- ✅ Rotate credentials periodically
- ✅ Use different values for dev and production

### DON'T ❌

- ❌ Never commit `.key` files to git
- ❌ Never share keys in plain text (Slack, email)
- ❌ Don't use production credentials in development
- ❌ Don't hardcode secrets in code
- ❌ Don't share screenshots of decrypted credentials

## Troubleshooting

### "InvalidMessage" Error

```
ActiveSupport::MessageEncryptor::InvalidMessage
```

**Problem:** Wrong RAILS_MASTER_KEY for the environment

**Solution:**
```bash
# Check which key is being used
echo $RAILS_MASTER_KEY

# Update to correct key
# Development: 043907ca426b48a8a8411287ecfd2455
# Production: c8993f9d8899d14d38a54140ba2c04be
```

### Key File Not Found

```
Error: Key file not found: config/credentials/development.key
```

**Solution:**
```bash
# Development key
echo "043907ca426b48a8a8411287ecfd2455" > config/credentials/development.key
chmod 600 config/credentials/development.key

# Production key
echo "c8993f9d8899d14d38a54140ba2c04be" > config/credentials/production.key
chmod 600 config/credentials/production.key
```

### Script Times Out

The `rails credentials:edit` command can hang. Use our script instead:

```bash
# Don't use this (can hang):
rails credentials:edit --environment development

# Use this instead:
scripts/credentials.sh --environment development edit
```

### Credentials Return Nil

```ruby
Rails.application.credentials.dig(:smtp, :address)
# => nil
```

**Possible causes:**
1. Wrong environment (check `Rails.env`)
2. Typo in key name
3. Credentials not saved properly

**Solution:**
```bash
# Verify credentials exist
scripts/credentials.sh --environment development show | grep smtp
```

## Migration from ENV Variables

If you have existing ENV vars, migrate them to credentials:

### Step 1: Document Current ENV Vars

```bash
# List current secrets
grep -E "(API|KEY|SECRET|PASSWORD)" .env.development
```

### Step 2: Add to Credentials

```bash
scripts/credentials.sh --environment development edit
# Copy values from .env to credentials YAML format
```

### Step 3: Test with Fallback

Code already supports fallback:
```ruby
ENV["SMTP_ADDRESS"] || Rails.application.credentials.dig(:smtp, :address)
```

Both work during transition.

### Step 4: Remove from ENV

Once verified working from credentials:
```bash
# Comment out or remove from .env.development
# SMTP_ADDRESS=...  # Now in credentials
```

### Step 5: Update Documentation

Update README or onboarding docs to reference credentials script.

## Advanced Usage

### Dump and Diff

Compare development vs production credentials:

```bash
# Dump both
scripts/credentials.sh --environment development dump > dev.yml
scripts/credentials.sh --environment production dump > prod.yml

# Compare
diff dev.yml prod.yml
```

### Bulk Updates with AI

```bash
# Get current credentials
scripts/credentials.sh --environment development dump > current.yml

# Send to AI for modification
ai-tool process current.yml > updated.yml

# Verify changes
diff current.yml updated.yml

# Apply if good
cat updated.yml | scripts/credentials.sh --environment development replace
```

### Backup Before Changes

The replace command auto-backs up, but you can also:

```bash
# Manual backup
cp config/credentials/production.yml.enc \
   config/credentials/production.yml.enc.$(date +%Y%m%d)
```

## Key Reference

### Current Keys

**Development:**
- Key: `043907ca426b48a8a8411287ecfd2455`
- File: `config/credentials/development.key`
- ENV: Set in `.env.development`

**Production:**
- Key: `c8993f9d8899d14d38a54140ba2c04be`
- File: `config/credentials/production.key`
- ENV: Set in `.kamal/secrets`

**Storage:**
- Store in 1Password, LastPass, or secure vault
- Never commit to git
- Share via encrypted channel only

## Resources

- [Rails Credentials Documentation](https://guides.rubyonrails.org/security.html#custom-credentials)
- [scripts/credentials.sh source code](../scripts/credentials.sh)
- [OnePunch CLAUDE.md](../CLAUDE.md)