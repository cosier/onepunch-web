# Testing Roadmap - OnePunch Web Application

**Last Updated:** 2025-10-17
**Current Coverage:** 9.69%
**Target Coverage:** 90%+

---

## Testing Philosophy

### Core Principles

1. **Test Behavior, Not Implementation** - Focus on what the code does, not how it does it
2. **AAA Pattern** - Arrange, Act, Assert for clear test structure
3. **One Assertion Per Concept** - Each test should verify one specific behavior
4. **Avoid Test Interdependence** - Tests should run independently in any order
5. **Use Factories Wisely** - Realistic data that reflects actual business scenarios
6. **Test Edge Cases** - Null values, empty arrays, boundary conditions
7. **Mock External Services** - API calls, background jobs, mailers

### Test Pyramid

```
        /\
       /  \  E2E Tests (5%)
      /----\
     /      \  Integration Tests (25%)
    /--------\
   /          \  Unit Tests (70%)
  /-----------  \
```

---

## Current State Analysis

### What's Working ✅
- **Authentication Flow** - 21 passing tests covering OAuth + API token auth
- **Factory Setup** - Basic factories for User, Organization, OAuth tokens
- **RSpec Configuration** - Rails helper, SimpleCov, FactoryBot integrated

### Critical Gaps ❌
- **No Model Tests** - 0% coverage on business logic
- **No Controller Tests** - Only API authentication covered
- **No Service Tests** - No coverage of business logic layer
- **No Integration Tests** - No end-to-end user flow testing
- **Incomplete Factories** - Missing realistic associations and callbacks

---

## Testing Roadmap

### Phase 1: Foundation (Week 1-2) - CURRENT

**Goal:** Establish testing infrastructure and core model coverage

#### 1.1 Model Tests - Critical Business Logic

**Priority: HIGH**

**User Model** (`spec/models/user_spec.rb`) - 23 tests
- [x] Email validation: presence
- [x] Email validation: format (valid email addresses)
- [x] Email validation: format (reject invalid formats)
- [x] Email validation: uniqueness (case insensitive)
- [ ] Email normalization: downcase before save
- [ ] Email normalization: strip whitespace
- [ ] Password validation: minimum length (8 characters)
- [ ] Password validation: presence on create
- [ ] Password validation: complexity requirements
- [ ] Password encryption: uses bcrypt
- [ ] Password encryption: doesn't store plaintext
- [ ] Name validation: first_name presence
- [ ] Name validation: last_name presence
- [ ] Association: has_many organizations through memberships
- [ ] Association: has_many time_entries
- [ ] Association: has_many api_tokens
- [ ] Association: has_many oauth_access_tokens
- [ ] Association: belongs_to current_organization (optional)
- [ ] Method #full_name: concatenates first + last name
- [ ] Method #switch_organization: updates current_organization
- [ ] Method #switch_organization: validates user is member
- [ ] Scope .active: excludes soft-deleted users
- [ ] Soft delete: sets deleted_at timestamp
- [ ] Soft delete: preserves associated data

**Organization Model** (`spec/models/organization_spec.rb`) - 28 tests
- [ ] Name validation: presence
- [ ] Name validation: minimum length (2 characters)
- [ ] Name validation: maximum length (100 characters)
- [ ] Slug validation: presence
- [ ] Slug validation: uniqueness (case insensitive)
- [ ] Slug validation: format (alphanumeric + hyphens only)
- [ ] Slug generation: auto-generates from name on create
- [ ] Slug generation: parameterizes name (spaces to hyphens)
- [ ] Slug generation: handles special characters
- [ ] Association: has_many members through organization_memberships
- [ ] Association: has_many projects (dependent: destroy)
- [ ] Association: has_many clients (dependent: destroy)
- [ ] Association: has_many invoices (through: projects)
- [ ] Association: has_many time_entries (through: projects)
- [ ] Association: has_one organization_settings
- [ ] Type validation: personal must have exactly 1 member
- [ ] Type validation: business can have unlimited members
- [ ] Method #add_member: creates organization_membership
- [ ] Method #add_member: sets default role (member)
- [ ] Method #add_member: prevents duplicate memberships
- [ ] Method #remove_member: soft deletes membership
- [ ] Method #owner?: checks if user is owner
- [ ] Method #admin?: checks if user is admin or owner
- [ ] Scope .personal: filters personal organizations
- [ ] Scope .business: filters business organizations
- [ ] Callback: creates default settings on create
- [ ] Soft delete: sets deleted_at timestamp
- [ ] Soft delete: cascades to projects and clients

**Project Model** (`spec/models/project_spec.rb`) - 35 tests
- [ ] Name validation: presence
- [ ] Name validation: minimum length (1 character)
- [ ] Name validation: uniqueness (scoped to organization)
- [ ] Hourly rate validation: numericality
- [ ] Hourly rate validation: greater than or equal to 0
- [ ] Hourly rate validation: precision (2 decimal places)
- [ ] Status validation: inclusion in allowed values (active, on_hold, completed)
- [ ] Color validation: format (hex color code #RRGGBB)
- [ ] Color validation: default value (#3B82F6 blue)
- [ ] Association: belongs_to organization
- [ ] Association: belongs_to client (optional)
- [ ] Association: has_many time_entries (dependent: destroy)
- [ ] Association: has_many invoice_line_items
- [ ] Scope .active: status = active, not archived
- [ ] Scope .archived: archived = true
- [ ] Scope .by_client: filters by client_id
- [ ] Scope .billable: hourly_rate > 0
- [ ] Scope .non_billable: hourly_rate = 0
- [ ] Scope .recent: ordered by updated_at desc
- [ ] Method #billable?: returns true if hourly_rate > 0
- [ ] Method #total_time: sums duration of all time_entries
- [ ] Method #total_billable: calculates total_time * hourly_rate
- [ ] Method #archive: sets archived = true, status = completed
- [ ] Method #unarchive: sets archived = false, status = active
- [ ] Method #status_active?: status == 'active'
- [ ] Method #status_on_hold?: status == 'on_hold'
- [ ] Method #status_completed?: status == 'completed'
- [ ] Callback: validates organization ownership on client assignment
- [ ] Callback: updates updated_at when time entry added
- [ ] Organization scoping: can't access project from different org
- [ ] Edge case: hourly_rate with 3+ decimals rounds to 2
- [ ] Edge case: negative hourly_rate rejected
- [ ] Edge case: zero hourly_rate allowed (non-billable)
- [ ] Edge case: very large hourly_rate (9999.99) allowed
- [ ] Edge case: empty string color defaults to blue

**TimeEntry Model** (`spec/models/time_entry_spec.rb`) - 42 tests
- [ ] Description validation: presence
- [ ] Description validation: minimum length (1 character)
- [ ] Description validation: maximum length (500 characters)
- [ ] Started_at validation: presence
- [ ] Started_at validation: can't be in future
- [ ] Ended_at validation: must be after started_at (if present)
- [ ] Project validation: presence (must belong to project)
- [ ] User validation: presence (must belong to user)
- [ ] Association: belongs_to user
- [ ] Association: belongs_to project
- [ ] Association: has_one organization (through: project)
- [ ] Method #duration: returns seconds between start and end
- [ ] Method #duration: returns 0 if ended_at is nil (running)
- [ ] Method #duration: handles same-day entries
- [ ] Method #duration: handles multi-day entries
- [ ] Method #running?: returns true if ended_at is nil
- [ ] Method #stopped?: returns true if ended_at present
- [ ] Method #stop: sets ended_at to current time
- [ ] Method #billable_amount: calculates duration * project.hourly_rate
- [ ] Method #billable_amount: returns 0 for non-billable projects
- [ ] Method #hours: converts duration to decimal hours (2.5h)
- [ ] Scope .today: filters by today's date
- [ ] Scope .this_week: filters by current week
- [ ] Scope .this_month: filters by current month
- [ ] Scope .between: filters by custom date range
- [ ] Scope .running: where ended_at is null
- [ ] Scope .stopped: where ended_at is not null
- [ ] Scope .for_project: filters by project_id
- [ ] Scope .for_user: filters by user_id
- [ ] Scope .billable: joins projects where hourly_rate > 0
- [ ] Validation: can't start new timer while another is running (same user)
- [ ] Validation: started_at can't be after current time + 1 minute (clock skew)
- [ ] Callback: rounds duration to nearest second
- [ ] Callback: updates project.updated_at when created
- [ ] Organization scoping: can only create entries for org projects
- [ ] Edge case: 0-second duration (start == end)
- [ ] Edge case: 24+ hour duration allowed
- [ ] Edge case: duration with milliseconds rounds to seconds
- [ ] Edge case: future started_at rejected
- [ ] Edge case: ended_at before started_at rejected
- [ ] Edge case: overlapping entries for same user (allowed)
- [ ] Edge case: simultaneous running timers (rejected)

**Invoice Model** (`spec/models/invoice_spec.rb`) - 38 tests
- [ ] Invoice number validation: presence
- [ ] Invoice number validation: uniqueness (scoped to organization)
- [ ] Invoice number validation: format (INV-YYYY-NNNN)
- [ ] Client validation: presence
- [ ] Organization validation: presence (through client)
- [ ] Due date validation: presence
- [ ] Due date validation: can't be in past (on create)
- [ ] Issue date validation: defaults to today
- [ ] Status validation: inclusion in (draft, sent, paid, overdue)
- [ ] Status validation: default value is 'draft'
- [ ] Association: belongs_to client
- [ ] Association: belongs_to organization (through: client)
- [ ] Association: has_many line_items (dependent: destroy)
- [ ] Association: has_many time_entries (through: line_items)
- [ ] Method #subtotal: sums line_item amounts
- [ ] Method #tax_amount: calculates subtotal * tax_rate
- [ ] Method #total: returns subtotal + tax_amount
- [ ] Method #mark_sent: transitions status to 'sent', sets sent_at
- [ ] Method #mark_paid: transitions status to 'paid', sets paid_at
- [ ] Method #overdue?: due_date < today && status != 'paid'
- [ ] Method #days_until_due: calculates days from today to due_date
- [ ] Method #days_overdue: calculates days past due_date (if overdue)
- [ ] State machine: draft → sent (only)
- [ ] State machine: sent → paid (only)
- [ ] State machine: can't go from paid → draft
- [ ] State machine: can't go from paid → sent
- [ ] State machine: auto-transitions to overdue if due_date passed
- [ ] Callback: generates invoice number on create
- [ ] Callback: invoice number uses sequential numbering per org
- [ ] Callback: sets issue_date to today on create
- [ ] Callback: sends email notification on mark_sent
- [ ] Callback: triggers PDF generation on mark_sent
- [ ] Scope .draft: status == 'draft'
- [ ] Scope .sent: status == 'sent'
- [ ] Scope .paid: status == 'paid'
- [ ] Scope .overdue: status == 'overdue' or (sent + past due_date)
- [ ] Scope .unpaid: status in (draft, sent, overdue)
- [ ] Organization scoping: can only access own org's invoices

**Client Model** (`spec/models/client_spec.rb`) - 22 tests
- [ ] Name validation: presence
- [ ] Name validation: minimum length (2 characters)
- [ ] Name validation: uniqueness (scoped to organization)
- [ ] Email validation: format (if present)
- [ ] Email validation: optional (can be blank)
- [ ] Phone validation: format (if present)
- [ ] Phone validation: optional (can be blank)
- [ ] Address validation: optional
- [ ] Organization validation: presence
- [ ] Association: belongs_to organization
- [ ] Association: has_many projects
- [ ] Association: has_many invoices
- [ ] Association: has_many time_entries (through: projects)
- [ ] Method #contact_info: returns formatted contact string
- [ ] Method #total_billed: sums all paid invoices
- [ ] Method #total_outstanding: sums unpaid invoices
- [ ] Method #active_projects: returns non-archived projects
- [ ] Scope .active: not soft-deleted
- [ ] Scope .with_projects: has at least one project
- [ ] Scope .search: fuzzy search by name, email, company
- [ ] Soft delete: sets deleted_at timestamp
- [ ] Soft delete: preserves projects and invoices

**ApiToken Model** (`spec/models/api_token_spec.rb`) - 18 tests
- [ ] Name validation: presence
- [ ] Name validation: minimum length (3 characters)
- [ ] Token validation: uniqueness
- [ ] Token validation: presence
- [ ] Expires_at validation: presence
- [ ] Expires_at validation: can't be in past (on create)
- [ ] User validation: presence
- [ ] Association: belongs_to user
- [ ] Callback: generates secure random token on create
- [ ] Callback: sets expires_at to 30 days from now (default)
- [ ] Callback: updates last_used_at on each use
- [ ] Method #active?: not revoked and not expired
- [ ] Method #expired?: expires_at < current time
- [ ] Method #revoked?: revoked_at present
- [ ] Method #revoke: sets revoked_at to current time
- [ ] Scope .active: not revoked, not expired
- [ ] Scope .expired: expires_at < current time
- [ ] Scope .revoked: revoked_at present

**OauthAccessToken Model** (`spec/models/oauth_access_token_spec.rb`) - 24 tests
- [ ] Token validation: presence
- [ ] Token validation: uniqueness
- [ ] Refresh token validation: presence
- [ ] Refresh token validation: uniqueness
- [ ] Expires_at validation: presence
- [ ] Scopes validation: presence
- [ ] User validation: presence
- [ ] Application validation: presence (oauth_application)
- [ ] Association: belongs_to user
- [ ] Association: belongs_to oauth_application
- [ ] Callback: generates secure random tokens on create
- [ ] Callback: sets expires_at based on expires_in (default 2 hours)
- [ ] Callback: updates last_used_at on each use
- [ ] Method #active?: not revoked and not expired
- [ ] Method #expired?: expires_at < current time
- [ ] Method #revoked?: revoked_at present
- [ ] Method #revoke: sets revoked_at to current time
- [ ] Method #scopes_list: splits scopes string into array
- [ ] Method #has_scope?: checks if specific scope granted
- [ ] Method #refresh: generates new access_token, keeps refresh_token
- [ ] Method #expires_in_seconds: calculates seconds until expiration
- [ ] Scope .active: not revoked, not expired
- [ ] Scope .expired: expires_at < current time
- [ ] Scope .revoked: revoked_at present

**Total Model Tests:** 230 tests

#### 1.2 Factory Improvements

**Priority: HIGH**

**Current Issues:**
- Hard-coded IDs (breaks associations)
- Unrealistic data (MyString, MyText)
- Missing trait variations (expired, revoked, archived)
- No sequence generation for unique fields

**Factory Improvements Needed:**

```ruby
# user.rb - Add realistic data + traits
factory :user do
  sequence(:email) { |n| "user#{n}@example.com" }
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  password { "SecurePass123!" }
  password_confirmation { password }

  trait :with_organization do
    after(:create) do |user|
      org = create(:organization)
      user.organizations << org
      user.update!(current_organization: org)
    end
  end

  trait :admin do
    admin { true }
  end
end

# organization.rb - Add traits for different types
factory :organization do
  sequence(:name) { |n| "Organization #{n}" }
  sequence(:slug) { |n| "org-#{n}" }

  trait :personal do
    personal { true }
    name { "Personal Org" }
  end

  trait :business do
    personal { false }
    name { Faker::Company.name }
  end

  trait :with_projects do
    after(:create) do |org|
      create_list(:project, 3, organization: org)
    end
  end
end

# project.rb - Add trait variations
factory :project do
  association :organization
  sequence(:name) { |n| "Project #{n}" }
  description { Faker::Lorem.paragraph }
  hourly_rate { rand(50.0..200.0).round(2) }
  status { "active" }
  color { "##{SecureRandom.hex(3)}" }

  trait :archived do
    archived { true }
  end

  trait :billable do
    hourly_rate { 150.00 }
  end

  trait :non_billable do
    hourly_rate { 0.00 }
  end

  trait :with_client do
    association :client
  end
end

# time_entry.rb - Add realistic time entries
factory :time_entry do
  association :user
  association :project
  description { Faker::Lorem.sentence }
  started_at { 2.hours.ago }
  ended_at { 1.hour.ago }

  trait :running do
    ended_at { nil }
  end

  trait :today do
    started_at { Time.current.beginning_of_day + 9.hours }
    ended_at { Time.current.beginning_of_day + 10.hours }
  end

  trait :billable do
    after(:create) do |entry|
      entry.project.update!(hourly_rate: 150.00)
    end
  end
end
```

#### 1.3 Request Specs - API Endpoints

**Priority: HIGH**

**Users API** (`spec/requests/api/v1/users_spec.rb`) - 14 tests
- [x] GET /api/v1/users/me: returns current user
- [x] GET /api/v1/users/me: includes organizations array
- [x] GET /api/v1/users/me: includes current_organization
- [x] GET /api/v1/users/me: returns 401 without authentication
- [x] GET /api/v1/users/me: wraps response in data envelope
- [ ] PATCH /api/v1/users/me: updates first_name
- [ ] PATCH /api/v1/users/me: updates last_name
- [ ] PATCH /api/v1/users/me: updates email (with confirmation)
- [ ] PATCH /api/v1/users/me: rejects invalid email format
- [ ] PATCH /api/v1/users/me: prevents duplicate email
- [ ] POST /api/v1/users/switch_organization: switches current org
- [ ] POST /api/v1/users/switch_organization: validates membership
- [ ] POST /api/v1/users/switch_organization: rejects non-member org
- [ ] POST /api/v1/users/switch_organization: returns updated user

**Timer API** (`spec/requests/api/v1/timer_spec.rb`) - 24 tests
- [ ] GET /api/v1/timer/current: returns running timer
- [ ] GET /api/v1/timer/current: returns null if no timer running
- [ ] GET /api/v1/timer/current: includes project details
- [ ] GET /api/v1/timer/current: includes duration calculation
- [ ] GET /api/v1/timer/current: scopes to current organization
- [ ] GET /api/v1/timer/current: returns 401 without authentication
- [ ] POST /api/v1/timer/start: creates new time_entry
- [ ] POST /api/v1/timer/start: sets started_at to now
- [ ] POST /api/v1/timer/start: leaves ended_at null
- [ ] POST /api/v1/timer/start: requires description
- [ ] POST /api/v1/timer/start: requires project_id
- [ ] POST /api/v1/timer/start: validates project belongs to org
- [ ] POST /api/v1/timer/start: rejects if timer already running
- [ ] POST /api/v1/timer/start: returns created timer
- [ ] POST /api/v1/timer/start: returns 422 with validation errors
- [ ] POST /api/v1/timer/stop: sets ended_at to now
- [ ] POST /api/v1/timer/stop: calculates duration
- [ ] POST /api/v1/timer/stop: returns stopped timer
- [ ] POST /api/v1/timer/stop: returns 404 if no timer running
- [ ] POST /api/v1/timer/stop: broadcasts Turbo Stream update
- [ ] PATCH /api/v1/timer/current: updates description
- [ ] PATCH /api/v1/timer/current: switches project
- [ ] PATCH /api/v1/timer/current: validates new project
- [ ] PATCH /api/v1/timer/current: returns 404 if not running

**Projects API** (`spec/requests/api/v1/projects_spec.rb`) - 38 tests
- [ ] GET /api/v1/projects: returns org-scoped projects
- [ ] GET /api/v1/projects: excludes other org projects
- [ ] GET /api/v1/projects: includes client association
- [ ] GET /api/v1/projects: filters by status=active
- [ ] GET /api/v1/projects: filters by status=archived
- [ ] GET /api/v1/projects: filters by client_id
- [ ] GET /api/v1/projects: orders by updated_at desc
- [ ] GET /api/v1/projects: returns 401 without auth
- [ ] GET /api/v1/projects: paginates results (25 per page)
- [ ] POST /api/v1/projects: creates project
- [ ] POST /api/v1/projects: sets organization from current_org
- [ ] POST /api/v1/projects: requires name
- [ ] POST /api/v1/projects: validates hourly_rate >= 0
- [ ] POST /api/v1/projects: validates color hex format
- [ ] POST /api/v1/projects: sets default color if blank
- [ ] POST /api/v1/projects: returns created project
- [ ] POST /api/v1/projects: returns 422 with validation errors
- [ ] POST /api/v1/projects: prevents client from different org
- [ ] GET /api/v1/projects/:id: returns project details
- [ ] GET /api/v1/projects/:id: includes time_entries summary
- [ ] GET /api/v1/projects/:id: includes total_time and total_billable
- [ ] GET /api/v1/projects/:id: returns 404 for non-existent project
- [ ] GET /api/v1/projects/:id: returns 404 for other org project
- [ ] PATCH /api/v1/projects/:id: updates name
- [ ] PATCH /api/v1/projects/:id: updates hourly_rate
- [ ] PATCH /api/v1/projects/:id: updates status
- [ ] PATCH /api/v1/projects/:id: updates color
- [ ] PATCH /api/v1/projects/:id: validates color format
- [ ] PATCH /api/v1/projects/:id: prevents moving to different org
- [ ] PATCH /api/v1/projects/:id: returns updated project
- [ ] PATCH /api/v1/projects/:id: returns 404 if not found
- [ ] DELETE /api/v1/projects/:id: archives project
- [ ] DELETE /api/v1/projects/:id: sets archived=true
- [ ] DELETE /api/v1/projects/:id: returns 204 no content
- [ ] DELETE /api/v1/projects/:id: returns 404 if not found
- [ ] DELETE /api/v1/projects/:id: prevents hard delete
- [ ] POST /api/v1/projects/:id/unarchive: unarchives project
- [ ] POST /api/v1/projects/:id/unarchive: sets archived=false

**Time Entries API** (`spec/requests/api/v1/time_entries_spec.rb`) - 45 tests
- [ ] GET /api/v1/time_entries: returns org-scoped entries
- [ ] GET /api/v1/time_entries: excludes other org entries
- [ ] GET /api/v1/time_entries: includes project details
- [ ] GET /api/v1/time_entries: includes user details
- [ ] GET /api/v1/time_entries: filters by start_date
- [ ] GET /api/v1/time_entries: filters by end_date
- [ ] GET /api/v1/time_entries: filters by date range
- [ ] GET /api/v1/time_entries: filters by project_id
- [ ] GET /api/v1/time_entries: filters by user_id
- [ ] GET /api/v1/time_entries: filters running entries
- [ ] GET /api/v1/time_entries: filters stopped entries
- [ ] GET /api/v1/time_entries: orders by started_at desc
- [ ] GET /api/v1/time_entries: paginates results
- [ ] GET /api/v1/time_entries: returns 401 without auth
- [ ] POST /api/v1/time_entries: creates entry
- [ ] POST /api/v1/time_entries: sets user to current_user
- [ ] POST /api/v1/time_entries: requires description
- [ ] POST /api/v1/time_entries: requires project_id
- [ ] POST /api/v1/time_entries: requires started_at
- [ ] POST /api/v1/time_entries: validates project belongs to org
- [ ] POST /api/v1/time_entries: validates started_at not in future
- [ ] POST /api/v1/time_entries: validates ended_at after started_at
- [ ] POST /api/v1/time_entries: calculates duration automatically
- [ ] POST /api/v1/time_entries: returns created entry
- [ ] POST /api/v1/time_entries: returns 422 with validation errors
- [ ] GET /api/v1/time_entries/:id: returns entry details
- [ ] GET /api/v1/time_entries/:id: includes duration
- [ ] GET /api/v1/time_entries/:id: includes billable_amount
- [ ] GET /api/v1/time_entries/:id: returns 404 if not found
- [ ] GET /api/v1/time_entries/:id: returns 404 for other org entry
- [ ] PATCH /api/v1/time_entries/:id: updates description
- [ ] PATCH /api/v1/time_entries/:id: updates started_at
- [ ] PATCH /api/v1/time_entries/:id: updates ended_at
- [ ] PATCH /api/v1/time_entries/:id: switches project (same org)
- [ ] PATCH /api/v1/time_entries/:id: recalculates duration
- [ ] PATCH /api/v1/time_entries/:id: validates dates
- [ ] PATCH /api/v1/time_entries/:id: prevents changing user
- [ ] PATCH /api/v1/time_entries/:id: returns updated entry
- [ ] PATCH /api/v1/time_entries/:id: returns 404 if not found
- [ ] DELETE /api/v1/time_entries/:id: deletes entry
- [ ] DELETE /api/v1/time_entries/:id: returns 204 no content
- [ ] DELETE /api/v1/time_entries/:id: returns 404 if not found
- [ ] DELETE /api/v1/time_entries/:id: prevents deleting other user's entry
- [ ] DELETE /api/v1/time_entries/:id: allows admin to delete any entry
- [ ] GET /api/v1/time_entries/today: returns today's entries

**Invoices API** (`spec/requests/api/v1/invoices_spec.rb`) - 42 tests
- [ ] GET /api/v1/invoices: returns org-scoped invoices
- [ ] GET /api/v1/invoices: excludes other org invoices
- [ ] GET /api/v1/invoices: includes client details
- [ ] GET /api/v1/invoices: includes line_items count
- [ ] GET /api/v1/invoices: filters by status=draft
- [ ] GET /api/v1/invoices: filters by status=sent
- [ ] GET /api/v1/invoices: filters by status=paid
- [ ] GET /api/v1/invoices: filters by client_id
- [ ] GET /api/v1/invoices: filters overdue invoices
- [ ] GET /api/v1/invoices: orders by created_at desc
- [ ] GET /api/v1/invoices: paginates results
- [ ] GET /api/v1/invoices: returns 401 without auth
- [ ] POST /api/v1/invoices: creates invoice
- [ ] POST /api/v1/invoices: generates invoice number
- [ ] POST /api/v1/invoices: sets organization from client
- [ ] POST /api/v1/invoices: requires client_id
- [ ] POST /api/v1/invoices: requires due_date
- [ ] POST /api/v1/invoices: validates client belongs to org
- [ ] POST /api/v1/invoices: creates line_items from time_entries
- [ ] POST /api/v1/invoices: calculates subtotal
- [ ] POST /api/v1/invoices: calculates tax_amount
- [ ] POST /api/v1/invoices: calculates total
- [ ] POST /api/v1/invoices: sets status to draft
- [ ] POST /api/v1/invoices: returns created invoice
- [ ] POST /api/v1/invoices: returns 422 with validation errors
- [ ] GET /api/v1/invoices/:id: returns invoice details
- [ ] GET /api/v1/invoices/:id: includes line_items
- [ ] GET /api/v1/invoices/:id: includes client
- [ ] GET /api/v1/invoices/:id: returns 404 if not found
- [ ] GET /api/v1/invoices/:id: returns 404 for other org invoice
- [ ] PATCH /api/v1/invoices/:id: updates due_date
- [ ] PATCH /api/v1/invoices/:id: updates notes
- [ ] PATCH /api/v1/invoices/:id: only allows updates if draft
- [ ] PATCH /api/v1/invoices/:id: returns 422 if sent/paid
- [ ] PATCH /api/v1/invoices/:id: returns updated invoice
- [ ] POST /api/v1/invoices/:id/send: marks as sent
- [ ] POST /api/v1/invoices/:id/send: sets sent_at timestamp
- [ ] POST /api/v1/invoices/:id/send: sends email notification
- [ ] POST /api/v1/invoices/:id/send: generates PDF
- [ ] POST /api/v1/invoices/:id/send: only allows if draft
- [ ] POST /api/v1/invoices/:id/pay: marks as paid
- [ ] POST /api/v1/invoices/:id/pay: sets paid_at timestamp

**Total Request Tests:** 163 tests

**Grand Total Tests (Model + Request):** 393 tests

---

### Phase 2: Controllers & Services (Week 3-4)

**Goal:** Test web controllers and business logic services

#### 2.1 Controller Tests

**Dashboard Controller** (`spec/controllers/dashboard_controller_spec.rb`)
- [ ] Index action - Load today's summary
- [ ] Weekly summary data
- [ ] Project breakdown
- [ ] Running timer detection

**Projects Controller** (`spec/controllers/projects_controller_spec.rb`)
- [ ] Index - Organization-scoped project list
- [ ] Show - Project details with time entries
- [ ] New/Create - Project creation workflow
- [ ] Edit/Update - Project updates
- [ ] Destroy - Soft delete
- [ ] Authorization (must be organization member)

**Time Entries Controller** (`spec/controllers/time_entries_controller_spec.rb`)
- [ ] Index - Date-filtered list
- [ ] Show - Entry details
- [ ] New/Create - Entry creation
- [ ] Edit/Update - Entry modification
- [ ] Destroy - Entry deletion
- [ ] Authorization (must own entry or be org admin)

**Timer Controller** (`spec/controllers/timer_controller_spec.rb`)
- [ ] Start - Start new timer
- [ ] Stop - Stop current timer
- [ ] Real-time updates via Turbo Streams

#### 2.2 Service Tests

**Purpose:** Services encapsulate complex business logic that doesn't belong in models or controllers.

**Invoice Generation Service** (`spec/services/invoice_generator_spec.rb`)
- [ ] Generate invoice from time entry selection
- [ ] Calculate totals correctly
- [ ] Handle different hourly rates per project
- [ ] Round amounts properly
- [ ] Generate unique invoice numbers
- [ ] Handle edge cases (no time entries, $0 rate)

**Timer Service** (`spec/services/timer_service_spec.rb`)
- [ ] Start timer (create time_entry without end_time)
- [ ] Stop timer (set end_time, calculate duration)
- [ ] Handle concurrent timer attempts
- [ ] Organization context validation

**Report Generator Service** (`spec/services/report_generator_spec.rb`)
- [ ] Weekly summary generation
- [ ] Monthly summary
- [ ] Project-based breakdown
- [ ] Client-based breakdown
- [ ] Export to CSV format

---

### Phase 3: Integration Tests (Week 5-6)

**Goal:** Test complete user workflows end-to-end

#### 3.1 System Tests (Capybara)

**User Registration & Onboarding** (`spec/system/onboarding_spec.rb`)
- [ ] Sign up with email/password
- [ ] Create first organization
- [ ] Setup first project
- [ ] Start first timer
- [ ] Stop timer and create entry

**Time Tracking Workflow** (`spec/system/time_tracking_spec.rb`)
- [ ] Start timer from dashboard
- [ ] Switch projects while timer running
- [ ] Stop timer after 2 hours
- [ ] Edit time entry retroactively
- [ ] Delete accidental entry

**Invoice Creation Workflow** (`spec/system/invoicing_spec.rb`)
- [ ] Select time entries for period
- [ ] Generate invoice draft
- [ ] Preview invoice PDF
- [ ] Send invoice to client
- [ ] Mark invoice as paid
- [ ] Download PDF receipt

**Multi-Organization Workflow** (`spec/system/multi_org_spec.rb`)
- [ ] User belongs to multiple orgs
- [ ] Switch between organizations
- [ ] Data isolation verification
- [ ] Can't see other org's data

#### 3.2 Integration Tests (Request Specs)

**Complete API Workflows** (`spec/requests/workflows/`)
- [ ] Full timer workflow (start → work → stop → invoice)
- [ ] Project lifecycle (create → track time → archive)
- [ ] Invoice lifecycle (draft → send → pay)

---

### Phase 4: Edge Cases & Performance (Week 7-8)

**Goal:** Handle edge cases, error scenarios, and performance bottlenecks

#### 4.1 Edge Case Testing

**Concurrency Issues**
- [ ] Two timers started simultaneously
- [ ] Invoice generated while time entry being edited
- [ ] Organization switch during timer running

**Boundary Conditions**
- [ ] 0-second time entries
- [ ] 24+ hour time entries
- [ ] Future-dated time entries
- [ ] Overlapping time entries

**Error Handling**
- [ ] Network timeouts during API calls
- [ ] Database connection failures
- [ ] Invalid data submissions
- [ ] Authorization failures

#### 4.2 Performance Tests

**Database Query Optimization** (`spec/performance/`)
- [ ] N+1 query detection (Bullet gem)
- [ ] Index usage verification
- [ ] Large dataset handling (1000+ time entries)
- [ ] Dashboard load time < 200ms

---

## Testing Tools & Configuration

### Gems

```ruby
# Gemfile
group :test do
  gem 'rspec-rails', '~> 6.1'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'faker', '~> 3.2'              # Realistic test data
  gem 'shoulda-matchers', '~> 6.0'  # Simplified model tests
  gem 'capybara', '~> 3.39'          # System tests
  gem 'selenium-webdriver', '~> 4.15' # Browser automation
  gem 'webmock', '~> 3.19'           # HTTP request stubbing
  gem 'vcr', '~> 6.2'                # Record HTTP interactions
  gem 'timecop', '~> 0.9'            # Time travel for tests
  gem 'database_cleaner-active_record', '~> 2.1'
  gem 'simplecov', '~> 0.22', require: false
  gem 'bullet', '~> 7.1'             # N+1 query detection
end
```

### RSpec Configuration

**Key Settings:**
- `config.use_transactional_fixtures = true` - Fast database cleanup
- `config.include FactoryBot::Syntax::Methods` - Shorter factory syntax
- `config.filter_run focus: true` - Run focused tests only
- `config.order = :random` - Catch test interdependence

### SimpleCov Configuration

**Coverage Thresholds:**
- Minimum: 90% line coverage
- Exclude: `config/`, `spec/`, `db/migrate/`

---

## Test Writing Guidelines

### Model Test Template

```ruby
# spec/models/project_spec.rb
require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'validations' do
    subject { build(:project) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:organization) }
    it { should validate_numericality_of(:hourly_rate).is_greater_than_or_equal_to(0) }
  end

  describe 'associations' do
    it { should belong_to(:organization) }
    it { should belong_to(:client).optional }
    it { should have_many(:time_entries).dependent(:destroy) }
  end

  describe 'scopes' do
    let(:org) { create(:organization) }
    let!(:active_project) { create(:project, organization: org, archived: false) }
    let!(:archived_project) { create(:project, organization: org, archived: true) }

    describe '.active' do
      it 'returns only non-archived projects' do
        expect(org.projects.active).to contain_exactly(active_project)
      end
    end
  end

  describe '#billable_amount' do
    context 'when project has hourly rate' do
      let(:project) { create(:project, hourly_rate: 100.00) }
      let!(:entry) { create(:time_entry, project: project, started_at: 2.hours.ago, ended_at: 1.hour.ago) }

      it 'calculates total billable amount' do
        expect(project.billable_amount).to eq(100.00) # 1 hour * $100/hr
      end
    end

    context 'when project is non-billable' do
      let(:project) { create(:project, hourly_rate: 0) }

      it 'returns zero' do
        expect(project.billable_amount).to eq(0)
      end
    end
  end
end
```

### Request Test Template

```ruby
# spec/requests/api/v1/projects_spec.rb
require 'rails_helper'

RSpec.describe 'Projects API', type: :request do
  let(:user) { create(:user, :with_organization) }
  let(:organization) { user.current_organization }
  let(:oauth_token) { create(:oauth_access_token, user: user) }
  let(:headers) { { 'Authorization' => "Bearer #{oauth_token.token}" } }

  describe 'GET /api/v1/projects' do
    let!(:project1) { create(:project, organization: organization) }
    let!(:project2) { create(:project, organization: organization) }
    let!(:other_org_project) { create(:project) } # Different org

    it 'returns organization-scoped projects' do
      get '/api/v1/projects', headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data'].size).to eq(2)
      expect(json['data'].map { |p| p['id'] }).to contain_exactly(project1.id, project2.id)
    end

    it 'does not return projects from other organizations' do
      get '/api/v1/projects', headers: headers

      json = JSON.parse(response.body)
      project_ids = json['data'].map { |p| p['id'] }
      expect(project_ids).not_to include(other_org_project.id)
    end
  end
end
```

---

## Success Metrics

### Phase 1 Complete
- [ ] 90% model coverage
- [ ] All API endpoints tested
- [ ] Factories produce realistic data
- [ ] Test suite runs < 30 seconds

### Phase 2 Complete
- [ ] 90% controller coverage
- [ ] All services tested
- [ ] Business logic edge cases covered

### Phase 3 Complete
- [ ] 5+ critical user workflows tested end-to-end
- [ ] System tests run in under 2 minutes

### Phase 4 Complete
- [ ] 90%+ overall coverage
- [ ] All known edge cases tested
- [ ] Performance benchmarks met

---

## Maintenance

### Weekly
- [ ] Review failing tests
- [ ] Update factories as models evolve
- [ ] Add tests for new features

### Monthly
- [ ] Review coverage reports
- [ ] Identify untested code paths
- [ ] Update testing roadmap

### Quarterly
- [ ] Gem updates
- [ ] Performance benchmarking
- [ ] Testing process retrospective

---

**Next Actions:**
1. ✅ Complete authentication test suite (DONE)
2. Create comprehensive model tests starting with User
3. Improve factory quality with realistic data
4. Add request specs for Timer API
5. Implement service layer with tests

**Owner:** Development Team
**Review Date:** Weekly
**Last Review:** 2025-10-17
