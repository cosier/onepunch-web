# Organization System Implementation Checklist

## Overview
This checklist provides a step-by-step implementation guide for adding the multi-tenant organization system to OnePunch. Follow these steps in order to ensure proper dependency management and avoid migration issues.

## Pre-Implementation Requirements

### ✅ Environment Setup
- [ ] Rails 8.1 edge (main branch) installed
- [ ] SQLite database configured
- [ ] Hotwire (Turbo + Stimulus) working
- [ ] Tailwind CSS configured
- [ ] Authentication system (Devise or custom) operational
- [ ] Google OAuth integration functional

### ✅ Development Tools
- [ ] Rails console access
- [ ] Database migration tools
- [ ] Test suite running
- [ ] Browser developer tools for debugging Stimulus

---

## Phase 1: Database Foundation (Day 1)

### 1.1 Create Organization Models
```bash
rails generate model Organization name:string slug:string:uniq \
  billing_email:string tax_id:string address:jsonb timezone:string \
  currency:string logo_url:string website:string industry:string \
  size:string onboarded_at:datetime trial_ends_at:datetime \
  subscription_status:string settings:jsonb
```
- [ ] Generate organization model
- [ ] Add indexes for performance
- [ ] Add validations for required fields
- [ ] Add slug generation (friendly_id or custom)

### 1.2 Create Membership Join Table
```bash
rails generate model Membership user:references organization:references \
  role:string joined_at:datetime invited_by:references permissions:jsonb
```
- [ ] Generate membership model
- [ ] Add unique index on [user_id, organization_id]
- [ ] Add role validations (owner, admin, member)
- [ ] Set default joined_at to current_timestamp

### 1.3 Update User Model
```bash
rails generate migration AddCurrentOrganizationToUsers \
  current_organization:references
```
- [ ] Add current_organization reference
- [ ] Add indexes for query performance
- [ ] Update User model associations
- [ ] Add organization helper methods

### 1.4 Create Invitations Table
```bash
rails generate model Invitation organization:references \
  invited_by:references email:string token:string:uniq \
  role:string accepted_at:datetime expires_at:datetime
```
- [ ] Generate invitation model
- [ ] Add secure token generation
- [ ] Add expiration logic (7 days default)
- [ ] Add email validations

### 1.5 Update Existing Models
- [ ] Add organization_id to projects table
- [ ] Add organization_id to clients table
- [ ] Add organization_id to invoices table
- [ ] Add migration for existing data (if any)
- [ ] Update all model associations

### 1.6 Run Migrations
```bash
rails db:migrate
rails db:migrate RAILS_ENV=test
```
- [ ] Run development migrations
- [ ] Run test migrations
- [ ] Verify schema.rb changes
- [ ] Create seed data for testing

---

## Phase 2: Model Implementation (Day 1-2)

### 2.1 Organization Model
- [ ] Add model validations
- [ ] Add friendly slug generation
- [ ] Add membership management methods
- [ ] Add statistics calculation methods
- [ ] Add subscription/billing helpers
- [ ] Add test coverage (> 90%)

### 2.2 Membership Model
- [ ] Add role-based permissions
- [ ] Add scope for active members
- [ ] Add invitation acceptance logic
- [ ] Add permission checking methods
- [ ] Add test coverage

### 2.3 User Model Updates
- [ ] Add organization switching logic
- [ ] Add onboarding status checks
- [ ] Add role helper methods
- [ ] Add organization access validations
- [ ] Update authentication callbacks
- [ ] Add test coverage

### 2.4 Invitation Model
- [ ] Add token generation (SecureRandom)
- [ ] Add email delivery logic
- [ ] Add acceptance workflow
- [ ] Add expiration handling
- [ ] Add test coverage

---

## Phase 3: Controller Implementation (Day 2-3)

### 3.1 Create OrganizationScoped Concern
```ruby
# app/controllers/concerns/organization_scoped.rb
```
- [ ] Create concern file
- [ ] Add before_action filters
- [ ] Add organization context methods
- [ ] Add scoping helpers
- [ ] Add authorization checks

### 3.2 Update ApplicationController
- [ ] Include authentication helpers
- [ ] Add current_organization helper
- [ ] Add organization requirement checks
- [ ] Update after_sign_in_path
- [ ] Add error handling

### 3.3 Create Organizations Controller
```bash
rails generate controller Organizations \
  index show new create edit update destroy
```
- [ ] Generate controller
- [ ] Add CRUD actions
- [ ] Add member management actions
- [ ] Add settings actions
- [ ] Add authorization filters
- [ ] Add test coverage

### 3.4 Create Onboarding Controller
```bash
rails generate controller Onboarding \
  new create update complete
```
- [ ] Generate controller
- [ ] Add wizard step management
- [ ] Add progress tracking
- [ ] Add completion logic
- [ ] Add test coverage

### 3.5 Create Organization Switcher Controller
```bash
rails generate controller OrganizationSwitcher switch
```
- [ ] Generate controller
- [ ] Add switch action
- [ ] Add session management
- [ ] Add redirect logic
- [ ] Add test coverage

### 3.6 Update Existing Controllers
- [ ] Add OrganizationScoped to ProjectsController
- [ ] Add OrganizationScoped to TimeEntriesController
- [ ] Add OrganizationScoped to InvoicesController
- [ ] Add OrganizationScoped to ClientsController
- [ ] Update all queries to scope by organization

---

## Phase 4: UI Implementation (Day 3-4)

### 4.1 Create Organization Switcher Component
- [ ] Create `_organization_switcher.html.erb` partial
- [ ] Add dropdown UI with search
- [ ] Add current organization indicator
- [ ] Add keyboard shortcuts (Cmd+K)
- [ ] Style with Tailwind CSS

### 4.2 Create Stimulus Controller
```bash
rails generate stimulus organization_switcher
```
- [ ] Generate Stimulus controller
- [ ] Add dropdown toggle logic
- [ ] Add search/filter functionality
- [ ] Add keyboard navigation
- [ ] Add click-outside handling

### 4.3 Update Application Layout
- [ ] Add organization switcher to navbar
- [ ] Add organization context display
- [ ] Update user menu dropdown
- [ ] Add organization settings link
- [ ] Ensure responsive design

### 4.4 Create Onboarding Wizard Views
- [ ] Create modal container partial
- [ ] Create Step 1: Organization details
- [ ] Create Step 2: Profile setup
- [ ] Create Step 3: First project
- [ ] Create Step 4: Team invites
- [ ] Create Step 5: Billing (optional)
- [ ] Add progress indicator
- [ ] Add animations/transitions

### 4.5 Create Onboarding Stimulus Controller
```bash
rails generate stimulus onboarding_wizard
```
- [ ] Generate controller
- [ ] Add step navigation
- [ ] Add form validation
- [ ] Add progress tracking
- [ ] Add skip/complete logic
- [ ] Add auto-save functionality

### 4.6 Organization Settings Pages
- [ ] Create settings layout
- [ ] Create general settings view
- [ ] Create members management view
- [ ] Create billing settings view
- [ ] Create integrations view
- [ ] Add role-based visibility

---

## Phase 5: API Implementation (Day 4-5)

### 5.1 Create API Namespace
```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :organizations
  end
end
```
- [ ] Add API routes
- [ ] Add versioning structure
- [ ] Add authentication middleware
- [ ] Add rate limiting

### 5.2 Create API Controllers
```bash
rails generate controller Api::V1::Organizations
rails generate controller Api::V1::Members
rails generate controller Api::V1::Invitations
```
- [ ] Generate API controllers
- [ ] Add JSON serializers
- [ ] Add error handling
- [ ] Add pagination
- [ ] Add filtering/sorting

### 5.3 Create JSON Serializers
- [ ] Organization serializer
- [ ] Member serializer
- [ ] Invitation serializer
- [ ] Statistics serializer
- [ ] Settings serializer

### 5.4 Add API Documentation
- [ ] Install API documentation gem (optional)
- [ ] Document all endpoints
- [ ] Add example requests/responses
- [ ] Create Postman collection
- [ ] Add SDK examples

---

## Phase 6: Testing (Day 5-6)

### 6.1 Model Tests
- [ ] Organization model specs
- [ ] Membership model specs
- [ ] Invitation model specs
- [ ] User organization methods specs
- [ ] Achieve > 95% coverage

### 6.2 Controller Tests
- [ ] Organizations controller specs
- [ ] Onboarding controller specs
- [ ] Organization switcher specs
- [ ] API controller specs
- [ ] Authorization tests

### 6.3 System Tests
```bash
rails generate system_test organizations
rails generate system_test onboarding
```
- [ ] Organization creation flow
- [ ] Onboarding wizard flow
- [ ] Organization switching
- [ ] Member invitation flow
- [ ] Settings management

### 6.4 Integration Tests
- [ ] Multi-organization data isolation
- [ ] Permission boundaries
- [ ] Invitation acceptance flow
- [ ] API authentication/authorization
- [ ] Real-time updates (Turbo)

---

## Phase 7: Security & Performance (Day 6)

### 7.1 Security Audit
- [ ] Verify data isolation between organizations
- [ ] Test authorization at all levels
- [ ] Validate invitation token security
- [ ] Check for SQL injection vulnerabilities
- [ ] Run brakeman security scan

### 7.2 Performance Optimization
- [ ] Add database indexes
- [ ] Implement query eager loading
- [ ] Add caching for organization data
- [ ] Optimize N+1 queries
- [ ] Add counter caches where needed

### 7.3 Database Optimization
```ruby
# Add these indexes
add_index :projects, [:organization_id, :created_at]
add_index :memberships, [:organization_id, :role]
add_index :users, :current_organization_id
```
- [ ] Add composite indexes
- [ ] Add foreign key constraints
- [ ] Optimize slow queries
- [ ] Add database views if needed

---

## Phase 8: Deployment Preparation (Day 7)

### 8.1 Migration Strategy
- [ ] Plan zero-downtime deployment
- [ ] Create data migration scripts
- [ ] Test rollback procedures
- [ ] Document migration steps

### 8.2 Feature Flags (Optional)
- [ ] Add feature flag for gradual rollout
- [ ] Configure flag management
- [ ] Test with flags on/off
- [ ] Plan rollout schedule

### 8.3 Monitoring Setup
- [ ] Add organization metrics
- [ ] Set up error tracking
- [ ] Configure performance monitoring
- [ ] Create health check endpoints

### 8.4 Documentation
- [ ] Update README
- [ ] Create user guides
- [ ] Document API changes
- [ ] Update CLAUDE.md

---

## Post-Launch Tasks

### Week 1
- [ ] Monitor system performance
- [ ] Gather user feedback
- [ ] Fix critical bugs
- [ ] Optimize slow queries

### Week 2
- [ ] Implement user feedback
- [ ] Add missing features
- [ ] Performance tuning
- [ ] Security audit

### Month 1
- [ ] Advanced features (templates, bulk operations)
- [ ] API v2 planning
- [ ] Mobile app updates
- [ ] Analytics dashboard

---

## Testing Checklist

### Manual Testing
- [ ] Create organization as new user
- [ ] Complete onboarding wizard
- [ ] Switch between organizations
- [ ] Invite team members
- [ ] Accept invitation as new user
- [ ] Manage organization settings
- [ ] Delete organization (owner only)
- [ ] API endpoints with Postman

### Automated Testing
```bash
# Run full test suite
rails test
rails test:system

# Run specific tests
rails test test/models/organization_test.rb
rails test test/controllers/organizations_controller_test.rb
rails test test/system/onboarding_test.rb
```

### Browser Testing
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile Safari (iOS)
- [ ] Chrome Mobile (Android)

---

## Rollback Plan

If issues arise during deployment:

1. **Database Rollback**
```bash
rails db:rollback STEP=5
```

2. **Code Rollback**
```bash
git revert [commit-hash]
kamal rollback
```

3. **Feature Flag Disable**
```ruby
Flipflop.disable!(:organizations)
```

4. **Data Recovery**
- Restore from backup
- Run recovery scripts
- Verify data integrity

---

## Success Metrics

### Technical Metrics
- [ ] Page load time < 200ms
- [ ] API response time < 100ms
- [ ] Test coverage > 90%
- [ ] Zero security vulnerabilities
- [ ] 99.9% uptime

### Business Metrics
- [ ] Onboarding completion rate > 80%
- [ ] Organization creation time < 2 minutes
- [ ] Member invitation acceptance > 70%
- [ ] User satisfaction score > 4.5/5

---

## Support Resources

### Documentation
- [Organization System Architecture](./organization_system.md)
- [Onboarding Wizard Guide](./onboarding_wizard.md)
- [API Documentation](./organization_api.md)
- [Rails Guides](https://guides.rubyonrails.org)
- [Hotwire Documentation](https://hotwired.dev)

### Team Contacts
- Technical Lead: [Contact]
- Product Owner: [Contact]
- DevOps: [Contact]
- QA Lead: [Contact]

---

## Notes

### Important Considerations
1. Always maintain backwards compatibility
2. Keep organization switching fast (< 100ms)
3. Ensure data isolation is bulletproof
4. Make onboarding skippable but encouraging
5. Plan for scale (1000+ organizations)

### Common Pitfalls to Avoid
1. Not scoping all queries by organization
2. Forgetting to update API documentation
3. Missing authorization checks
4. Not testing organization switching thoroughly
5. Ignoring performance impact of joins

---

## Sign-off

- [ ] Development Complete
- [ ] Code Review Passed
- [ ] QA Testing Passed
- [ ] Security Review Passed
- [ ] Documentation Complete
- [ ] Deployment Approved

**Implementation Start Date:** ___________
**Target Completion Date:** ___________
**Actual Completion Date:** ___________

**Developer:** ___________
**Reviewer:** ___________
**Approver:** ___________