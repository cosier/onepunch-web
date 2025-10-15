# GEMINI.md

This file provides guidance to Gemini when working with code in this repository.

## Commands

### Development Server
```bash
# Start Rails server and Tailwind CSS watcher (recommended)
./bin/dev

# Or start individually:
rails server -p 2030          # Rails server on port 2030
rails tailwindcss:watch        # Tailwind CSS watcher
```

### Database
```bash
rails db:create                # Create database
rails db:migrate               # Run migrations
rails db:seed                  # Load seed data
rails db:rollback              # Rollback last migration
rails db:reset                 # Drop, create, migrate and seed
```

### Testing & Code Quality
```bash
rails test                     # Run all tests
rails test test/models         # Run model tests
rails test:system              # Run system tests

rubocop                        # Ruby linting with Omakase style
rubocop -A                     # Auto-fix linting issues

brakeman                       # Security vulnerability scan
```

### Tailwind CSS
```bash
rails tailwindcss:build        # Build CSS for production
rails tailwindcss:watch        # Watch for changes (development)
```

### Background Jobs
```bash
rails solid_queue:start        # Start Solid Queue worker
```

### Deployment
```bash
bin/deploy                     # Deploy application (handles secrets automatically)
kamal setup                    # First time deployment setup
kamal rollback                 # Rollback deployment
```

### Rails Encrypted Credentials
```bash
# View credentials (read-only)
scripts/credentials.sh --environment development show
scripts/credentials.sh --environment production show

# Edit credentials (opens in $EDITOR)
scripts/credentials.sh --environment development edit
scripts/credentials.sh --environment production edit

# Dump credentials as YAML (for piping to AI/scripts)
scripts/credentials.sh --environment development dump

# Replace credentials from stdin (for AI/automation)
cat new_credentials.yml | scripts/credentials.sh --environment development replace
```

**Important Notes:**
- The script automatically uses the correct key file for each environment
- Development key: `config/credentials/development.key` (not in git)
- Production key: `config/credentials/production.key` (not in git)
- Encrypted files (.yml.enc) ARE committed to git
- See `docs/reference/credentials.md` for detailed documentation

## Development Workflow with an AI Assistant

### Git Commit & Deploy Protocol
When working with an AI assistant, follow this efficient workflow:

1. **Make changes** to fix bugs or implement features
2. **Commit early and often** after completing logical chunks of work:
   ```bash
   git add <files>
   git commit -m "Brief description of changes"
   ```
3. **Deploy in background** after commits (do NOT wait for deployment to finish):
   ```bash
   bin/deploy &
   ```
4. **Continue working** on next tasks while deployment runs in background
5. **Check deployment status** only when needed:
   ```bash
   # Deployment typically takes 30-60 seconds
   # Only check if something seems wrong
   ```

### Best Practices
- Commit after every 2-3 related fixes or after completing a feature
- Keep commit messages concise (1-2 sentences, no signoff)
- Deploy in background to avoid blocking progress
- Continue with testing and next tasks while deployment runs
- Only interrupt workflow if deployment fails

### Git Branch Strategy
This repository uses a three-branch workflow:

- **master**: Pristine branch, fast-forward only merges from develop
- **develop**: Primary development branch for day-to-day work
- **production**: Deployment branch, receives merge --no-ff from anywhere

```bash
# Development workflow
git checkout develop              # Work on develop branch
git add . && git commit -m "..."  # Commit changes

# Merge to master (fast-forward only)
git checkout master
git merge --ff-only develop

# Deploy to production (no fast-forward)
git checkout production
git merge --no-ff develop        # Or merge from any branch
git push origin production       # Triggers automatic deployment via GitHub Actions
```

**Deployment**: Pushing to `production` branch triggers automatic deployment to 100.64.0.48 via Tailscale through GitHub Actions.

## Secrets Management

### Encrypted Credentials Strategy
OnePunch uses Rails encrypted credentials for secure secret management:

**File Structure:**
- `config/credentials/development.yml.enc` - Development secrets (encrypted, committed to git)
- `config/credentials/development.key` - Development decryption key (NOT in git, local only)
- `config/credentials/production.yml.enc` - Production secrets (encrypted, committed to git)
- `config/credentials/production.key` - Production decryption key (NOT in git, deploy server only)

**Credentials Format:**
```yaml
# SMTP Configuration (AWS SES)
smtp:
  address: email-smtp.us-west-2.amazonaws.com
  port: 587
  user_name: USERNAME
  password: PASSWORD
  domain: onepunch.work

# Google OAuth
google:
  client_id: YOUR_CLIENT_ID
  client_secret: YOUR_CLIENT_SECRET

# Stripe
stripe:
  publishable_key: pk_...
  secret_key: sk_...
```

**Accessing Credentials in Code:**
```ruby
# Credentials with ENV fallback
Rails.application.credentials.dig(:smtp, :address)  # First tries credentials
ENV["SMTP_ADDRESS"]  # Falls back to ENV var

# In config/environments/*.rb
config.action_mailer.smtp_settings = {
  address: ENV["SMTP_ADDRESS"] || Rails.application.credentials.dig(:smtp, :address),
  # ... other settings
}
```

**Deployment:**
- Only `RAILS_MASTER_KEY` needs to be set in `.kamal/secrets`
- All other secrets are encrypted in the repository
- Kamal deploys the encrypted files and uses RAILS_MASTER_KEY to decrypt

**Benefits:**
- ✅ One secret to manage (RAILS_MASTER_KEY) instead of 10+ ENV vars
- ✅ Secrets committed encrypted in git (auditable history)
- ✅ No risk of leaking .env files
- ✅ Easy to manage with `scripts/credentials.sh` helper
- ✅ AI/automation friendly with dump/replace commands

## Architecture

### Rails 8.1 No-Build Philosophy
This application follows Rails 8.1's no-build approach:
- **JavaScript**: Import maps (no bundler, no node_modules for JS)
- **CSS**: Tailwind standalone CLI (no Node.js required)
- **Assets**: Sprockets for images and fonts
- **Libraries**: Loaded via CDN with importmap-rails

### Technology Stack
- **Framework**: Rails 8.1 edge (main branch)
- **Database**: PostgreSQL 15+
- **Background Jobs**: Solid Queue (Rails 8 native)
- **Caching**: Solid Cache
- **WebSockets**: Solid Cable
- **Frontend**: Hotwire (Turbo 8 + Stimulus 3)
- **Styling**: Tailwind CSS (standalone CLI)
- **Deployment**: Kamal 2 + Thruster
- **Ruby Version**: 3.4.5 (managed by mise)

### Key Models & Relationships
The application is a time tracking and invoicing system with these core models:

- **User**: Authentication, has many projects/time entries through organization
- **Organization**: Multi-tenancy container for all business data
- **Project**: Billable work units with hourly rates
- **TimeEntry**: Time tracking records (start/stop timer)
- **Invoice**: Billing documents generated from time entries
- **Client**: Customer entities that receive invoices

### Real-time Features
- Turbo Streams for live updates (timer, dashboard)
- ActionCable for presence tracking
- Server-side timer state management

### Mobile Support
- Progressive Web App (PWA) with service worker
- Hotwire Native for Android app wrapper
- Web Push notifications via VAPID

## Development Workflow

### Current Implementation Status
The project follows a TODO-based development approach. Check `docs/todo/` for active implementation plans covering:
- Authentication (email/password + Google OAuth)
- Time tracking with live timer
- Invoice generation with PDF export
- Real-time dashboard updates

## Documentation Structure

All project documentation is organized in `docs/` with the following structure:

### `/docs/todo/` - Active Work Items
Contains active implementation tasks currently in progress or planned for near-term execution.

**Files:**
- `01-mvp-launch.md` - Core MVP features
- `02-multi-org-filtering.md` - Multi-organization filtering
- `README.md` - Index of active TODOs with status

**Naming Convention:** `NN-feature-name.md` (numbered sequentially)

### `/docs/planning/` - Architecture & Design
Contains architectural designs, feature specifications, and long-term planning documents.

**Files:**
- `organization-system.md` - Multi-tenant architecture
- `onboarding-wizard.md` - User onboarding flow
- `organization-api.md` - REST API specifications
- `implementation-checklist.md` - Step-by-step guides
- `README.md` - Planning docs index

**Use for:** System design, feature specs, API docs, technical decisions

### `/docs/testing/` - Test Documentation
Contains test coverage plans, testing strategies, and QA documentation.

**Files:**
- `coverage-plan.md` - Test implementation roadmap
- `coverage-index.md` - Comprehensive test file index
- `README.md` - Testing guide with commands

**Current Coverage:** 18.31% (target: 90%+)

### `/docs/reference/` - Reference Guides
Contains reference documentation that doesn't fit other categories.

**Files:**
- `style-guide.md` - UI/UX design system
- `credentials.md` - Secrets management guide
- `api.md` - Full API documentation
- `api-quickstart.md` - Quick start guide

**Use for:** Style guides, credentials, API docs, quick references

### `/docs/completed/` - Completed Work Archive
Contains completed TODOs and deprecated planning docs for historical reference.

**Structure:** Organized by quarter (e.g., `2025-Q1/`)

**Purpose:** Historical record, learning resource, progress tracking

### Documentation Workflow

1. **Planning a Feature**
   - Create design doc in `docs/planning/feature-name.md`
   - Include: overview, requirements, design, implementation steps
   - Get feedback and approval

2. **Ready to Implement**
   - Create TODO in `docs/todo/NN-feature-name.md`
   - Reference the planning doc
   - Break into actionable tasks with checkboxes

3. **During Implementation**
   - Update TODO file with progress
   - Mark completed tasks
   - Note any deviations from plan

4. **After Completion**
   - Add completion date and notes to TODO
   - Move to `docs/completed/YYYY-QX/`
   - Update `docs/completed/README.md`
   - Remove from `docs/todo/README.md`

### Finding Documentation

- **Active work?** → Check `docs/todo/README.md`
- **How is X designed?** → Check `docs/planning/`
- **Test coverage?** → Check `docs/testing/`
- **Style guidelines?** → Check `docs/reference/style-guide.md`
- **API docs?** → Check `docs/reference/api.md`
- **Credentials?** → Check `docs/reference/credentials.md`
- **Was X completed?** → Check `docs/completed/`

### Port Configuration
The application runs on port **2030** by default (configured in Procfile.dev and bin/dev).

### Environment Variables
Development environment uses mise for tool management (.mise.toml) with:
- Ruby 3.4.5
- Node 24.6.0 (for Tailwind CSS CLI only)
- PostgreSQL 15

### Database Configuration
- Development: `onepunch_development`
- Test: `onepunch_test`
- Uses PostgreSQL with standard Rails database.yml configuration

## Design & Style Guidelines

### Layout Consistency
- **Container Width**: Always use `max-w-7xl` for page containers to maintain consistency
- **Page Structure**: `<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">`
- **Avoid** using `max-w-4xl` or other widths unless specifically needed for modals or special components

### UI Components
- **Cards**: Use white background with shadow and rounded corners (`bg-white shadow rounded-lg`)
- **Headers**: Page headers should include title and description with action buttons on the right
- **Buttons**: Primary actions use `bg-indigo-600 hover:bg-indigo-700` with white text
- **Status Badges**: Use colored badges with appropriate semantic colors
  - Success/Active: Green (`bg-green-100 text-green-800`)
  - Warning/Trial: Yellow (`bg-yellow-100 text-yellow-800`)
  - Error/Expired: Red (`bg-red-100 text-red-800`)
  - Info/Personal: Blue (`bg-blue-100 text-blue-800`)
  - Default/Business: Gray (`bg-gray-100 text-gray-800`)

### Navigation
- **Top Navigation**: Fixed header with organization switcher (when user has multiple orgs)
- **Settings Pages**: Use tabbed navigation for settings sections
- **Page Actions**: Place primary action buttons (Create, New, Add) in top-right of page header

### Forms
- **Input Fields**: Use Tailwind form plugin classes with focus states
- **Labels**: Always include labels with `text-sm font-medium text-gray-700`
- **Error States**: Display inline error messages with red styling
- **Submit Buttons**: Right-aligned in footer with Cancel option

### Organization Features
- **Personal Organizations**: Display as "Personal Org." in UI, limit 1 per user
- **Business Organizations**: Regular display with full name
- **Organization Switcher**: Only show when user has more than 1 organization
- **Settings**: Organization-scoped settings with switcher at top of settings pages

## Data Scoping & Multi-Tenancy

### Organization-Based Data Isolation
All data is scoped to the current organization to ensure proper multi-tenant isolation:

```ruby
# Time entries must be scoped through organization's projects
org_project_ids = current_organization&.projects&.pluck(:id) || []
scoped_entries = current_user.time_entries.where(project_id: org_project_ids)

# Projects are directly scoped to organization
@projects = current_organization&.projects&.active || []

# Current organization is available via helper method
current_organization  # Returns user's current_organization
```

### Key Scoping Patterns
- **Time Entries**: Always filter through `project_id` using organization's projects
- **Projects**: Directly associated with organization
- **Clients**: Belong to organization
- **Invoices**: Scoped through organization
- **User Access**: Users can belong to multiple organizations, but view data from one at a time

### Controller Patterns
```ruby
# In controllers, always scope queries:
before_action :authenticate_user!

def index
  # Get organization's project IDs for scoping
  org_project_ids = current_organization&.projects&.pluck(:id) || []

  # Scope time entries through projects
  @time_entries = current_user.time_entries
    .where(project_id: org_project_ids)
    .recent
    .includes(:project)
end
```
