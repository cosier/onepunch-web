# Test Coverage Index

This document tracks all test files needed to achieve 100% code coverage for the OnePunch application.

**Current Coverage**: 18.31% (286/1562 lines)
**Target Coverage**: 100%
**Last Updated**: 2025-09-30

---

## Legend
- ✅ **Complete**: Test file exists with comprehensive coverage
- 🔄 **In Progress**: Test file exists but needs fixes or improvements
- ⏳ **Planned**: Test file needs to be created
- 🔴 **Blocked**: Depends on other tests or functionality

---

## Models (app/models/)

### Core Models
- ✅ **user_spec.rb** - 52 tests - User authentication, associations, OAuth
- ✅ **organization_spec.rb** - 45 tests - Multi-tenancy, settings, memberships
- ✅ **project_spec.rb** - 29 tests - Project management, billing, calculations
- ✅ **time_entry_spec.rb** - 27 tests - Time tracking, duration calculations
- ✅ **membership_spec.rb** - 16 tests - User-organization relationships, roles
- ✅ **client_spec.rb** - 16 tests - Client management, revenue tracking
- 🔄 **organization_setting_spec.rb** - 21 tests (10 failing) - Invoice settings, defaults

### Invoice & Billing Models
- ⏳ **invoice_spec.rb** - Invoice generation, payment tracking, PDF export
  - Test invoice number generation
  - Test payment status transitions (draft → sent → paid → overdue)
  - Test total calculations
  - Test date validations
  - Test scopes (paid, unpaid, overdue, draft)

- ⏳ **invoice_line_item_spec.rb** - Line items, calculations
  - Test associations with invoice
  - Test amount calculations
  - Test quantity and rate validations
  - Test description requirements

### Invitation & Access Models
- ⏳ **invitation_spec.rb** - User invitations, team collaboration
  - Test email validation
  - Test token generation and uniqueness
  - Test expiration logic
  - Test acceptance flow
  - Test role assignment
  - Test scopes (pending, accepted, expired)
  - Test callbacks (send invitation email)

### Asana Integration Models
- ⏳ **asana_credential_spec.rb** - OAuth credentials, token management
  - Test associations with user
  - Test token expiration checking
  - Test token refresh logic
  - Test unique Asana account validation
  - Test expired? method

- ⏳ **asana_workspace_spec.rb** - Workspace sync
  - Test associations
  - Test workspace sync status
  - Test last_synced_at tracking

- ⏳ **asana_project_spec.rb** - Project mapping
  - Test associations
  - Test project sync
  - Test mapping to OnePunch projects

- ⏳ **asana_task_spec.rb** - Task sync
  - Test associations
  - Test time entry creation from tasks
  - Test task completion status

### AI Features
- ⏳ **summary_spec.rb** - AI summaries, content generation
  - Test associations
  - Test summary generation
  - Test content validation

### Concerns
- ⏳ **onboarding_requirement_spec.rb** - User onboarding flow
  - Test onboarding checks
  - Test redirect logic

---

## Controllers (app/controllers/)

### Authentication & Sessions
- ⏳ **sessions_controller_spec.rb** - Login, logout, OAuth
  - Test GET /login renders form
  - Test POST /login with valid credentials
  - Test POST /login with invalid credentials
  - Test DELETE /logout destroys session
  - Test Google OAuth callback success
  - Test Google OAuth callback failure
  - Test redirect to intended page after login

- ⏳ **registrations_controller_spec.rb** - User signup
  - Test GET /signup renders form
  - Test POST /signup creates user and organization
  - Test POST /signup with invalid data
  - Test email uniqueness validation
  - Test password requirements
  - Test automatic login after registration

### Dashboard & Home
- ⏳ **dashboard_controller_spec.rb** - Main dashboard
  - Test authentication required
  - Test organization scoping
  - Test time entry summaries
  - Test recent activity display
  - Test current timer display

### Core Resources
- ⏳ **projects_controller_spec.rb** - CRUD operations
  - Test index with organization scoping
  - Test show project details
  - Test create project
  - Test update project
  - Test archive/unarchive project
  - Test authorization checks
  - Test organization fallback logic

- ⏳ **time_entries_controller_spec.rb** - Time tracking
  - Test index with filtering (today, week, date range)
  - Test create time entry
  - Test update time entry
  - Test delete time entry
  - Test organization project scoping
  - Test billable status toggle
  - Test bulk operations

- ⏳ **timer_controller_spec.rb** - Start/stop timer
  - Test start timer
  - Test stop timer
  - Test current timer status
  - Test only one running timer per user
  - Test auto-stop previous timer

- ⏳ **clients_controller_spec.rb** - Client management
  - Test CRUD operations
  - Test organization scoping
  - Test associated projects display

- ⏳ **invoices_controller_spec.rb** - Invoice generation
  - Test index with filters
  - Test create invoice from time entries
  - Test update invoice
  - Test mark as paid
  - Test PDF generation
  - Test email sending

### Settings
- ⏳ **settings_controller_spec.rb** - User preferences
  - Test index displays settings
  - Test update profile
  - Test update password
  - Test update preferences

- ⏳ **settings/integrations_controller_spec.rb** - External integrations
  - Test Asana integration page
  - Test connect Asana account
  - Test disconnect Asana account
  - Test sync status display

- ⏳ **settings/organizations_controller_spec.rb** - Org settings
  - Test organization settings page
  - Test update organization
  - Test update billing settings
  - Test invoice settings

### Organizations
- ⏳ **organizations_controller_spec.rb** - Organization management
  - Test index lists user's organizations
  - Test show organization details
  - Test create new organization
  - Test switch organization
  - Test update organization
  - Test member management

- ⏳ **memberships_controller_spec.rb** - Team members
  - Test index team members
  - Test invite member
  - Test update member role
  - Test remove member
  - Test owner protections

- ⏳ **invitations_controller_spec.rb** - Invitation handling
  - Test show invitation
  - Test accept invitation
  - Test decline invitation
  - Test resend invitation
  - Test cancel invitation

### Asana Integration
- ⏳ **asana_oauth_controller_spec.rb** - OAuth flow
  - Test initiate OAuth
  - Test OAuth callback success
  - Test OAuth callback with existing account error
  - Test token storage

- ⏳ **asana_sync_controller_spec.rb** - Data sync
  - Test sync workspaces
  - Test sync projects
  - Test sync tasks
  - Test sync status display

### Admin
- ⏳ **admin/dashboard_controller_spec.rb** - Admin overview
  - Test super_admin required
  - Test statistics display

- ⏳ **admin/users_controller_spec.rb** - User management
  - Test index users
  - Test show user details
  - Test update user role
  - Test impersonate user

- ⏳ **admin/base_controller_spec.rb** - Admin authorization
  - Test authentication required
  - Test super_admin authorization

---

## Services (app/services/)

- ⏳ **asana_api_service_spec.rb** - Asana API wrapper
  - Test authentication
  - Test fetch workspaces
  - Test fetch projects
  - Test fetch tasks
  - Test create time entry from task
  - Test error handling
  - Test rate limiting
  - Test token refresh

---

## Jobs (app/jobs/)

- ⏳ **asana_sync_job_spec.rb** - Background sync
  - Test workspace sync
  - Test project sync
  - Test task sync
  - Test error handling
  - Test retry logic

- ⏳ **application_job_spec.rb** - Base job configuration
  - Test queue configuration
  - Test error handling

---

## Mailers (app/mailers/)

- ⏳ **application_mailer_spec.rb** - Base mailer
  - Test default from address
  - Test layout

- ⏳ **invitation_mailer_spec.rb** - Invitation emails
  - Test invitation email content
  - Test invitation email recipients
  - Test invitation link

- ⏳ **invoice_mailer_spec.rb** - Invoice emails
  - Test invoice email content
  - Test PDF attachment
  - Test recipient

---

## Lib (lib/)

- ⏳ **summarize_spec.rb** - AI summarization
  - Test summary generation
  - Test different content types
  - Test error handling
  - Test API integration

---

## Request/Integration Tests

- ⏳ **full_workflow_spec.rb** - End-to-end scenarios
  - Test user registration → create org → create project → track time → generate invoice
  - Test team collaboration → invite member → accept → track time
  - Test Asana integration → connect → sync → import tasks
  - Test invoice workflow → create → send → mark paid
  - Test organization switching → create multiple orgs → switch context

---

## System/Feature Tests (if using Capybara)

- ⏳ **authentication_system_spec.rb** - Login/logout flows
- ⏳ **time_tracking_system_spec.rb** - Timer and time entry UI
- ⏳ **invoice_generation_system_spec.rb** - Invoice creation flow
- ⏳ **organization_switching_system_spec.rb** - Multi-org navigation

---

## Test Helpers & Support Files

### Existing
- ✅ **spec/rails_helper.rb** - Rails test configuration
- ✅ **spec/spec_helper.rb** - SimpleCov configuration
- ✅ **spec/support/factory_bot.rb** - FactoryBot config
- ✅ **spec/support/shoulda_matchers.rb** - Shoulda matchers config

### Needed
- ⏳ **spec/support/vcr.rb** - VCR configuration for HTTP mocking
- ⏳ **spec/support/authentication_helpers.rb** - Login helpers for tests
- ⏳ **spec/support/shared_examples/** - Shared examples for common patterns
  - ⏳ **organization_scoped_examples.rb** - Shared examples for org-scoped resources
  - ⏳ **authenticated_request_examples.rb** - Shared examples for auth required
  - ⏳ **crud_examples.rb** - Shared CRUD operation examples

---

## Factories (test/factories/)

### Existing
- ✅ **users.rb** - User factory with traits
- ✅ **organizations.rb** - Organization factory
- ✅ **projects.rb** - Project factory
- ✅ **time_entries.rb** - TimeEntry factory
- ✅ **memberships.rb** - Membership factory
- ✅ **clients.rb** - Client factory
- ✅ **organization_settings.rb** - OrganizationSetting factory

### Needed
- ⏳ **invoices.rb** - Invoice factory with traits (paid, unpaid, draft, overdue)
- ⏳ **invoice_line_items.rb** - InvoiceLineItem factory
- ⏳ **invitations.rb** - Invitation factory (pending, accepted, expired)
- ⏳ **asana_credentials.rb** - AsanaCredential factory
- ⏳ **asana_workspaces.rb** - AsanaWorkspace factory
- ⏳ **asana_projects.rb** - AsanaProject factory
- ⏳ **asana_tasks.rb** - AsanaTask factory
- ⏳ **summaries.rb** - Summary factory (already exists)

---

## Priority Order

### Phase 1: Critical Business Logic (Week 1)
1. ✅ Fix OrganizationSetting tests (10 failures)
2. ⏳ Invoice model + controller tests
3. ⏳ InvoiceLineItem model tests
4. ⏳ Projects controller tests
5. ⏳ Time entries controller tests

### Phase 2: Authentication & Access (Week 2)
1. ⏳ Sessions controller tests
2. ⏳ Registrations controller tests
3. ⏳ Invitation model + controller tests
4. ⏳ Memberships controller tests
5. ⏳ Organizations controller tests

### Phase 3: Integrations (Week 3)
1. ⏳ Asana models (credential, workspace, project, task)
2. ⏳ AsanaApiService tests
3. ⏳ Asana OAuth controller tests
4. ⏳ Asana sync job tests
5. ⏳ Asana sync controller tests

### Phase 4: Additional Features (Week 4)
1. ⏳ Dashboard controller tests
2. ⏳ Timer controller tests
3. ⏳ Settings controllers tests
4. ⏳ Client controller tests
5. ⏳ Summary model tests

### Phase 5: Admin & Polish (Week 5)
1. ⏳ Admin controllers tests
2. ⏳ Mailer tests
3. ⏳ Request/integration tests
4. ⏳ System tests
5. ⏳ Cleanup and edge cases

---

## Coverage Targets

- **Models**: 100% (critical for business logic)
- **Controllers**: 90%+ (key user flows)
- **Services**: 95%+ (external API integrations)
- **Jobs**: 90%+ (background processing)
- **Mailers**: 85%+ (email delivery)
- **Overall**: 90%+

---

## Notes

- Focus on **quality over quantity** - each test should verify behavior, not just coverage
- Use **shoulda-matchers** for simple validations/associations
- Use **FactoryBot** for test data - keep factories simple and composable
- Use **VCR** for external API calls (Asana, AI services)
- Write **integration tests** for critical user journeys
- Keep tests **fast** - use `build` instead of `create` when possible
- Follow **AAA pattern**: Arrange, Act, Assert
- Use **descriptive test names** that explain what is being tested
- Group related tests with **describe** and **context** blocks

---

## Progress Tracking

Update this section after completing each test file:

**Week 1 Progress**:
- [x] User model (52 tests) ✅
- [x] Organization model (45 tests) ✅
- [x] Project model (29 tests) ✅
- [x] TimeEntry model (27 tests) ✅
- [x] Membership model (16 tests) ✅
- [x] Client model (16 tests) ✅
- [ ] OrganizationSetting model (fix 10 failures) 🔄
- [ ] Invoice model ⏳
- [ ] InvoiceLineItem model ⏳

**Coverage Milestones**:
- [x] 10% coverage (achieved: 18.31% ✅)
- [ ] 25% coverage
- [ ] 50% coverage
- [ ] 75% coverage
- [ ] 90% coverage (target)

---

## Quick Reference Commands

```bash
# Run all tests
bundle exec rspec

# Run specific model tests
bundle exec rspec spec/models/user_spec.rb

# Run with coverage
bundle exec rspec

# View coverage report
open coverage/index.html

# Run tests matching pattern
bundle exec rspec spec/models/ --pattern "*user*"

# Run failed tests only
bundle exec rspec --only-failures

# Run tests with documentation format
bundle exec rspec --format documentation

# Check coverage percentage
bundle exec rspec | grep "Line Coverage"
```