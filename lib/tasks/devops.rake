# DevOps tasks for debugging and token management
namespace :devops do
  namespace :tokens do
    desc "Create an OAuth access token for a user (usage: rake devops:tokens:create[email,scopes])"
    task :create, [:email, :scopes] => :environment do |t, args|
      email = args[:email] || ENV['USER_EMAIL']
      scopes = args[:scopes] || 'api'

      if email.nil?
        puts "❌ Error: User email required"
        puts "Usage: rake devops:tokens:create[email@example.com,api]"
        puts "   or: USER_EMAIL=email@example.com rake devops:tokens:create"
        exit 1
      end

      user = User.find_by(email: email)
      unless user
        puts "❌ Error: User not found with email: #{email}"
        puts "\nAvailable users:"
        User.limit(10).each do |u|
          puts "  - #{u.email}"
        end
        exit 1
      end

      # Find or create the OAuth application
      oauth_app = OauthApplication.find_by(client_id: 'onepunch_desktop_client')
      unless oauth_app
        puts "❌ Error: OAuth application 'onepunch_desktop_client' not found"
        puts "Run: rails db:seed"
        exit 1
      end

      # Create access token
      token = OauthAccessToken.create!(
        oauth_application: oauth_app,
        user: user,
        scopes: scopes
        # expires_at is set automatically by before_validation callback
      )

      # Get token JSON (includes expires_in calculation)
      token_json = token.as_json
      expires_in_seconds = token_json[:expires_in]

      puts "✅ Access Token Created"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "User:         #{user.email}"
      puts "Token:        #{token.token}"
      puts "Scopes:       #{token.scopes}"
      puts "Expires:      #{token.expires_at.strftime('%Y-%m-%d %H:%M:%S %Z')}"
      puts "Expires In:   #{expires_in_seconds} seconds (#{expires_in_seconds / 86400} days)"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts ""
      puts "📋 Save to CLI tokens.json:"
      puts ""

      puts JSON.pretty_generate(token_json)
      puts ""
      puts "💾 To save this token for CLI:"
      puts "cat > ~/.config/onepunch/cli/tokens.json << 'EOF'"
      puts JSON.pretty_generate(token_json)
      puts "EOF"
      puts ""
      puts "🧪 Test with CLI:"
      puts "cd /projects/onepunch/cli"
      puts "./onepunch --json --dev | jq '.authenticated'"
    end

    desc "List all active OAuth tokens"
    task list: :environment do
      tokens = OauthAccessToken
        .includes(:user, :oauth_application)
        .where(revoked_at: nil)
        .order(created_at: :desc)

      if tokens.empty?
        puts "No active tokens found"
        exit 0
      end

      puts "Active OAuth Tokens"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

      tokens.each do |token|
        user = token.user
        app = token.oauth_application
        is_expired = token.expired?

        status = is_expired ? "❌ EXPIRED" : "✅ VALID"

        puts ""
        puts "#{status} Token ##{token.id}"
        puts "  User:        #{user.email}"
        puts "  Application: #{app.name}"
        puts "  Scopes:      #{token.scopes}"
        puts "  Created:     #{token.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
        puts "  Expires:     #{token.expires_at.strftime('%Y-%m-%d %H:%M:%S')}"

        if is_expired
          puts "  Expired:     #{((Time.current - token.expires_at) / 86400).round(1)} days ago"
        else
          puts "  Remaining:   #{((token.expires_at - Time.current) / 86400).round(1)} days"
        end

        puts "  Token:       #{token.token[0..15]}..." # Show first 16 chars
      end

      puts ""
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "Total: #{tokens.count} tokens"
    end

    desc "Revoke a token by ID or token string"
    task :revoke, [:token_id_or_string] => :environment do |t, args|
      identifier = args[:token_id_or_string] || ENV['TOKEN']

      if identifier.nil?
        puts "❌ Error: Token ID or string required"
        puts "Usage: rake devops:tokens:revoke[123]"
        puts "   or: TOKEN=abc123... rake devops:tokens:revoke"
        exit 1
      end

      # Try to find by ID first, then by token string
      token = if identifier.match?(/^\d+$/)
        OauthAccessToken.find_by(id: identifier)
      else
        OauthAccessToken.find_by(token: identifier)
      end

      unless token
        puts "❌ Error: Token not found: #{identifier}"
        exit 1
      end

      user = token.resource_owner
      token.update!(revoked_at: Time.current)

      puts "✅ Token revoked"
      puts "  User:   #{user.email}"
      puts "  Token:  #{token.token[0..15]}..."
      puts "  Status: Revoked at #{token.revoked_at.strftime('%Y-%m-%d %H:%M:%S')}"
    end

    desc "Clean up expired tokens (older than 30 days)"
    task cleanup: :environment do
      cutoff = 30.days.ago

      expired_tokens = OauthAccessToken.where('created_at < ?', cutoff)
      count = expired_tokens.count

      if count == 0
        puts "No expired tokens to clean up"
        exit 0
      end

      puts "Found #{count} expired tokens (older than #{cutoff.strftime('%Y-%m-%d')})"
      puts "Deleting..."

      expired_tokens.delete_all

      puts "✅ Cleaned up #{count} expired tokens"
    end

    desc "Show token details and test it against the API"
    task :inspect, [:token_string] => :environment do |t, args|
      token_string = args[:token_string] || ENV['TOKEN']

      if token_string.nil?
        puts "❌ Error: Token string required"
        puts "Usage: rake devops:tokens:inspect[abc123...]"
        puts "   or: TOKEN=abc123... rake devops:tokens:inspect"
        exit 1
      end

      token = OauthAccessToken.find_by(token: token_string)

      unless token
        puts "❌ Error: Token not found in database"
        puts ""
        puts "This could mean:"
        puts "  1. Token was revoked or deleted"
        puts "  2. Token is from a different environment (dev vs production)"
        puts "  3. Invalid token string"
        exit 1
      end

      user = token.user
      app = token.oauth_application
      is_expired = token.expired?
      is_revoked = token.revoked?

      puts "OAuth Token Inspection"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts ""
      puts "📋 Token Details:"
      puts "  ID:          #{token.id}"
      puts "  Token:       #{token.token}"
      puts "  Application: #{app.name} (#{app.client_id})"
      puts "  Scopes:      #{token.scopes}"
      puts ""
      puts "👤 User Details:"
      puts "  ID:          #{user.id}"
      puts "  Email:       #{user.email}"
      puts "  Name:        #{user.name}"
      puts ""
      expires_in_seconds = token.as_json[:expires_in]

      puts "⏰ Validity:"
      puts "  Created:     #{token.created_at.strftime('%Y-%m-%d %H:%M:%S %Z')}"
      puts "  Expires:     #{token.expires_at.strftime('%Y-%m-%d %H:%M:%S %Z')}"
      puts "  Expires In:  #{expires_in_seconds} seconds (#{expires_in_seconds / 86400} days)"

      if is_revoked
        puts "  Status:      ❌ REVOKED (#{token.revoked_at.strftime('%Y-%m-%d %H:%M:%S')})"
      elsif is_expired
        puts "  Status:      ❌ EXPIRED (#{((Time.current - token.expires_at) / 86400).round(1)} days ago)"
      else
        puts "  Status:      ✅ VALID (#{((token.expires_at - Time.current) / 86400).round(1)} days remaining)"
      end

      puts ""
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

      if is_expired || is_revoked
        puts ""
        puts "⚠️  This token is no longer valid"
        puts ""
        puts "To create a new token:"
        puts "  rake devops:tokens:create[#{user.email}]"
      end
    end

    desc "Export token in CLI format (usage: rake devops:tokens:export[email])"
    task :export, [:email] => :environment do |t, args|
      email = args[:email] || ENV['USER_EMAIL']

      if email.nil?
        puts "❌ Error: User email required"
        puts "Usage: rake devops:tokens:export[email@example.com]"
        exit 1
      end

      user = User.find_by(email: email)
      unless user
        puts "❌ Error: User not found: #{email}"
        exit 1
      end

      # Find most recent valid token for this user
      token = OauthAccessToken
        .where(user_id: user.id, revoked_at: nil)
        .where('expires_at > ?', Time.current)
        .order(created_at: :desc)
        .first

      unless token
        puts "❌ Error: No valid tokens found for user: #{email}"
        puts ""
        puts "Create a new token:"
        puts "  rake devops:tokens:create[#{email}]"
        exit 1
      end

      # Generate CLI-compatible JSON using as_json
      token_json = token.as_json

      puts JSON.pretty_generate(token_json)
    end
  end

  namespace :oauth do
    desc "List all OAuth applications"
    task list_apps: :environment do
      apps = OauthApplication.all

      if apps.empty?
        puts "No OAuth applications found"
        puts "Run: rails db:seed"
        exit 0
      end

      puts "OAuth Applications"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

      apps.each do |app|
        token_count = OauthAccessToken.where(oauth_application_id: app.id, revoked_at: nil).count

        puts ""
        puts "Application: #{app.name}"
        puts "  Client ID:     #{app.client_id}"
        puts "  Redirect URIs: #{app.redirect_uris}"
        puts "  Scopes:        #{app.scopes}"
        puts "  Confidential:  #{app.confidential}"
        puts "  Active Tokens: #{token_count}"
      end

      puts ""
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    end

    desc "Show OAuth stats"
    task stats: :environment do
      total_apps = OauthApplication.count
      total_tokens = OauthAccessToken.count
      active_tokens = OauthAccessToken.where(revoked_at: nil).count
      revoked_tokens = OauthAccessToken.where.not(revoked_at: nil).count

      # Count expired tokens
      expired_tokens = OauthAccessToken.expired.where(revoked_at: nil).count

      valid_tokens = active_tokens - expired_tokens

      puts "OAuth Statistics"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts ""
      puts "Applications:     #{total_apps}"
      puts ""
      puts "Tokens:"
      puts "  Total:          #{total_tokens}"
      puts "  ✅ Valid:       #{valid_tokens}"
      puts "  ⏰ Expired:     #{expired_tokens}"
      puts "  ❌ Revoked:     #{revoked_tokens}"
      puts ""
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    end
  end
end
