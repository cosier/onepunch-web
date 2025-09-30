#!/usr/bin/env bash
# Rails Credentials Management Script
#
# Usage:
#   scripts/credentials.sh --environment development show
#   scripts/credentials.sh --environment production edit
#   scripts/credentials.sh --environment development dump
#   scripts/credentials.sh --environment production replace < new_credentials.yml

set -e

# Default values
ENVIRONMENT=""
COMMAND=""
EDITOR="${EDITOR:-vim}"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --environment|-e)
      ENVIRONMENT="$2"
      shift 2
      ;;
    show|edit|dump|replace)
      COMMAND="$1"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate arguments
if [[ -z "$ENVIRONMENT" ]]; then
  echo "Error: --environment is required"
  echo ""
  echo "Usage:"
  echo "  scripts/credentials.sh --environment development show"
  echo "  scripts/credentials.sh --environment production edit"
  echo "  scripts/credentials.sh --environment development dump"
  echo "  scripts/credentials.sh --environment production replace < new_credentials.yml"
  exit 1
fi

if [[ -z "$COMMAND" ]]; then
  echo "Error: command is required (show, edit, dump, or replace)"
  exit 1
fi

# Set the appropriate key based on environment
if [[ "$ENVIRONMENT" == "development" ]]; then
  KEY_PATH="config/credentials/development.key"
elif [[ "$ENVIRONMENT" == "production" ]]; then
  KEY_PATH="config/credentials/production.key"
else
  KEY_PATH="config/master.key"
fi

# Check if key exists
if [[ ! -f "$KEY_PATH" ]]; then
  echo "Error: Key file not found: $KEY_PATH"
  echo "Run 'rails credentials:edit --environment $ENVIRONMENT' to create it first"
  exit 1
fi

# Export the master key for rails commands
export RAILS_MASTER_KEY=$(cat "$KEY_PATH")

# Execute the command
case $COMMAND in
  show)
    echo "=== Credentials for $ENVIRONMENT environment ==="
    rails credentials:show --environment "$ENVIRONMENT"
    ;;

  edit)
    echo "=== Editing credentials for $ENVIRONMENT environment ==="
    EDITOR="$EDITOR" rails credentials:edit --environment "$ENVIRONMENT"
    ;;

  dump)
    # Output raw YAML for piping or AI processing
    rails credentials:show --environment "$ENVIRONMENT"
    ;;

  replace)
    # Read new credentials from stdin and encrypt them
    echo "=== Replacing credentials for $ENVIRONMENT environment ==="
    echo "Reading new credentials from stdin..."

    TEMP_FILE=$(mktemp)
    cat > "$TEMP_FILE"

    # Validate YAML syntax
    if ! ruby -ryaml -e "YAML.load_file('$TEMP_FILE')" > /dev/null 2>&1; then
      echo "Error: Invalid YAML syntax"
      rm "$TEMP_FILE"
      exit 1
    fi

    # Backup existing credentials
    CRED_FILE="config/credentials/${ENVIRONMENT}.yml.enc"
    if [[ "$ENVIRONMENT" == "master" ]]; then
      CRED_FILE="config/credentials.yml.enc"
    fi

    if [[ -f "$CRED_FILE" ]]; then
      cp "$CRED_FILE" "${CRED_FILE}.backup"
      echo "Backed up existing credentials to ${CRED_FILE}.backup"
    fi

    # Use Rails to encrypt the new content
    # This is a bit tricky - we'll use a temporary environment variable approach
    CONTENT=$(cat "$TEMP_FILE")

    # Write to credentials using Rails runner with correct environment
    # Set SECRET_KEY_BASE so Rails can boot without needing to read credentials first
    SECRET_KEY_BASE="dummy_key_for_credentials_update" RAILS_ENV="$ENVIRONMENT" rails runner "
      require 'active_support/encrypted_configuration'
      credentials = Rails.application.encrypted('config/credentials/${ENVIRONMENT}.yml.enc', key_path: '${KEY_PATH}')
      credentials.write(File.read('${TEMP_FILE}'))
      puts 'Credentials updated successfully'
    "

    rm "$TEMP_FILE"
    echo "✓ Credentials replaced successfully for $ENVIRONMENT"
    ;;

  *)
    echo "Unknown command: $COMMAND"
    exit 1
    ;;
esac