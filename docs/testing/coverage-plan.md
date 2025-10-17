# Test Coverage Plan - OnePunch

**Current Status:** 9.67% (153 / 1582 lines)
**Target:** 90%+ overall coverage, 80%+ per file

## Coverage Analysis

### Files with 0% Coverage (Priority: HIGH)

#### Controllers
- `admin/base_controller.rb` - 11 lines
- `timer_controller.rb` - 70 lines

#### Jobs
- `application_job.rb` - 2 lines
- `asana_sync_job.rb` - 31 lines

#### Models
- `asana_project.rb` - 34 lines
- `asana_task.rb` - 46 lines
- `asana_workspace.rb` - 30 lines
- `client.rb` - 14 lines
- `invitation.rb` - 49 lines
- `invoice.rb` - 31 lines
- `invoice_line_item.rb` - 11 lines
- `organization_setting.rb` - 17 lines
- `project.rb` - 27 lines
- `summary.rb` - 64 lines

#### Mailers
- `application_mailer.rb` - 4 lines

### Current Test Coverage

✅ **AsanaApiService** - 100% (17 examples, all passing)

## Test Implementation Plan

### Phase 1: Critical Models (Week 1)
**Target: +30% coverage**

1. **User Model** - Core authentication & authorization
   - Test validations (email, password, name)
   - Test OAuth methods (`from_omniauth`)
   - Test organization relationships
   - Test role methods (`role_in`, `owner_of?`, `admin_of?`)
   - Test Asana integration methods

2. **Organization Model** - Multi-tenancy
   - Test validations (name, slug uniqueness)
   - Test callbacks (slug generation, settings creation)
   - Test scopes (personal, business, active)
   - Test member management

3. **Project Model** - Core business logic
   - Test validations
   - Test status enum
   - Test scopes (active, archived)
   - Test associations (time_entries, organization)

4. **TimeEntry Model** - Time tracking
   - Test validations
   - Test duration calculation
   - Test timer start/stop logic
   - Test scopes (running, stopped, recent)

5. **Membership Model** - Roles & permissions
   - Test validations
   - Test role enum
   - Test uniqueness constraints

### Phase 2: Asana Integration (Week 2)
**Target: +15% coverage**

1. **AsanaWorkspace** - Sync logic
   - Test `sync_workspaces` class method
   - Test `sync_projects` instance method
   - Test associations

2. **AsanaProject** - Project mapping
   - Test `sync_from_asana` class method
   - Test validations
   - Test associations

3. **AsanaTask** - Task management
   - Test scopes (unassigned, assigned, incomplete)
   - Test `display_name`
   - Test search functionality
   - Test associations

4. **AsanaCredential** - Token management
   - Test `expired?` method
   - Test `refresh_token!` method
   - Test validations (uniqueness of asana_user_gid)

5. **AsanaSyncJob** - Background processing
   - Test job enqueuing
   - Test sync workflow
   - Test error handling & retry logic

### Phase 3: Controllers (Week 3)
**Target: +20% coverage**

1. **ProjectsController**
   - Test CRUD operations
   - Test organization scoping
   - Test fallback logic for organization selection
   - Test archive/unarchive

2. **TimeEntriesController**
   - Test timer start/stop
   - Test CRUD operations
   - Test Asana task association
   - Test organization scoping

3. **OrganizationsController**
   - Test show action
   - Test switching organizations
   - Test member management

4. **Settings::IntegrationsController**
   - Test Asana OAuth flow
   - Test sync actions
   - Test disconnect

5. **AsanaOauthController**
   - Test authorize redirect
   - Test callback with token exchange
   - Test duplicate account prevention
   - Test error handling

### Phase 4: Additional Features (Week 4)
**Target: +15% coverage**

1. **Invoice & Billing**
   - Invoice model tests
   - InvoiceLineItem tests
   - PDF generation tests

2. **Client Management**
   - Client model tests
   - Client controller tests

3. **Invitation System**
   - Invitation model tests
   - Invitation acceptance flow

4. **Summary Feature**
   - Summary model tests
   - AI summarization (mock external calls)

### Phase 5: Request/Integration Tests (Week 5)
**Target: +10% coverage**

1. **Authentication Flow**
   - Email/password signup
   - Email/password login
   - Google OAuth flow
   - Session management

2. **Onboarding Flow**
   - Organization creation
   - First project creation
   - Profile completion

3. **Time Tracking Flow**
   - Start timer
   - Stop timer
   - Edit entries
   - Filter by date/project

4. **Asana Integration Flow**
   - Connect Asana account
   - Sync workspaces
   - Select tasks
   - Associate with time entries

## Testing Best Practices

### 1. Factory Setup
✅ Already created factories for:
- User
- Organization
- Membership
- Project
- TimeEntry
- AsanaCredential
- AsanaWorkspace
- AsanaProject
- AsanaTask

### 2. Test Structure
```ruby
RSpec.describe Model do
  describe 'associations' do
    # Test belongs_to, has_many, etc.
  end

  describe 'validations' do
    # Test presence, uniqueness, format, etc.
  end

  describe 'scopes' do
    # Test custom scopes
  end

  describe 'instance methods' do
    # Test public methods
  end

  describe 'class methods' do
    # Test class-level methods
  end
end
```

### 3. Controller Testing
```ruby
RSpec.describe Controller, type: :request do
  let(:user) { create(:user, :with_current_organization) }

  before { sign_in user }

  describe 'GET #index' do
    # Test successful responses
    # Test authorization
    # Test scoping
  end
end
```

### 4. Job Testing
```ruby
RSpec.describe Job do
  describe '#perform' do
    # Test job logic
    # Test error handling
    # Test retry logic
  end
end
```

## Commands

### Run all tests with coverage
```bash
bundle exec rspec
```

### Run specific test file
```bash
bundle exec rspec spec/models/user_spec.rb
```

### View coverage report
```bash
open coverage/index.html
```

### Generate coverage without running tests
```bash
COVERAGE=true bundle exec rspec
```

## Success Criteria

- ✅ All critical paths tested
- ✅ 90%+ overall line coverage
- ✅ 80%+ coverage per file
- ✅ All models have validation tests
- ✅ All controllers have happy path tests
- ✅ All background jobs have tests
- ✅ Integration tests for key user flows

## Next Steps

1. Start with User model tests (highest priority)
2. Add Organization and Membership tests
3. Add Project and TimeEntry tests
4. Continue through phases 2-5
5. Regularly run coverage reports to track progress
6. Add tests for any bugs found in production

## Notes

- SimpleCov configured with 90% minimum coverage threshold
- Coverage reports generated in `/coverage/` directory
- HTML reports available at `coverage/index.html`
- Console output shows bottom 15 worst-covered files
- Current coverage: **9.67%** (baseline established)