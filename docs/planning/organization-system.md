# Organization System Architecture

## Overview
OnePunch implements a multi-tenant architecture where all business data is scoped to Organizations. Users can belong to multiple organizations and switch between them seamlessly.

## Core Concepts

### Organization Context
Every authenticated session maintains an "active organization" context that determines:
- Which projects are visible
- Which time entries are shown
- Which clients are accessible
- Which invoices can be viewed/created
- Team members visible in the UI

### User-Organization Relationship
```
User ←→ Membership ←→ Organization
         ↓
       [role: owner|admin|member]
       [joined_at]
       [invited_by]
```

## Database Schema Updates

### 1. Add current_organization_id to users
```ruby
class AddCurrentOrganizationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :current_organization, foreign_key: { to_table: :organizations }
    add_index :users, [:id, :current_organization_id]
  end
end
```

### 2. Enhance organizations table
```ruby
class EnhanceOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :logo_url, :string
    add_column :organizations, :website, :string
    add_column :organizations, :industry, :string
    add_column :organizations, :size, :string # 'solo', 'small', 'medium', 'large'
    add_column :organizations, :onboarded_at, :datetime
    add_column :organizations, :trial_ends_at, :datetime
    add_column :organizations, :subscription_status, :string, default: 'trial'
  end
end
```

### 3. Add invitation system
```ruby
class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :invited_by, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.string :token, null: false
      t.string :role, default: 'member'
      t.datetime :accepted_at
      t.datetime :expires_at
      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, [:organization_id, :email]
  end
end
```

## Model Enhancements

### User Model
```ruby
class User < ApplicationRecord
  # Associations
  belongs_to :current_organization, class_name: 'Organization', optional: true
  has_many :owned_organizations, -> { where(memberships: { role: 'owner' }) },
           through: :memberships, source: :organization

  # Methods
  def switch_organization!(organization)
    return false unless organizations.include?(organization)
    update!(current_organization: organization)
    true
  end

  def needs_onboarding?
    organizations.empty?
  end

  def can_access_organization?(organization)
    organizations.include?(organization)
  end

  def role_in(organization)
    memberships.find_by(organization: organization)&.role
  end
end
```

### Organization Model
```ruby
class Organization < ApplicationRecord
  # Scopes
  scope :onboarded, -> { where.not(onboarded_at: nil) }
  scope :in_trial, -> { where(subscription_status: 'trial') }

  # Methods
  def onboarded?
    onboarded_at.present?
  end

  def complete_onboarding!
    update!(onboarded_at: Time.current)
  end

  def add_member(user, role: 'member', invited_by: nil)
    memberships.create!(
      user: user,
      role: role,
      invited_by: invited_by
    )
  end
end
```

## Controller Concerns

### OrganizationScoped Concern
```ruby
module OrganizationScoped
  extend ActiveSupport::Concern

  included do
    before_action :require_organization!
    before_action :set_organization_context
  end

  private

  def require_organization!
    if current_user.needs_onboarding?
      redirect_to onboarding_path
    elsif current_user.current_organization.nil?
      current_user.switch_organization!(current_user.organizations.first)
    end
  end

  def set_organization_context
    @current_organization = current_user.current_organization
  end

  def scope_to_organization(relation)
    relation.where(organization: @current_organization)
  end
end
```

## ApplicationController Updates
```ruby
class ApplicationController < ActionController::Base
  helper_method :current_organization

  def current_organization
    @current_organization ||= current_user&.current_organization
  end

  def after_sign_in_path_for(user)
    if user.needs_onboarding?
      onboarding_path
    else
      dashboard_path
    end
  end
end
```

## Organization Switcher UI

### Navbar Component
```erb
<!-- app/views/shared/_organization_switcher.html.erb -->
<div data-controller="organization-switcher" class="relative">
  <button data-action="click->organization-switcher#toggle"
          class="flex items-center space-x-2 px-3 py-2 rounded-lg hover:bg-gray-100">
    <% if current_organization.logo_url.present? %>
      <%= image_tag current_organization.logo_url, class: "w-6 h-6 rounded" %>
    <% else %>
      <div class="w-6 h-6 bg-indigo-500 rounded flex items-center justify-center">
        <span class="text-white text-xs font-bold">
          <%= current_organization.name[0].upcase %>
        </span>
      </div>
    <% end %>

    <span class="font-medium text-gray-900">
      <%= current_organization.name %>
    </span>

    <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M8 9l4-4 4 4m0 6l-4 4-4-4" />
    </svg>
  </button>

  <div data-organization-switcher-target="dropdown"
       class="hidden absolute top-full left-0 mt-1 w-64 bg-white rounded-lg shadow-lg border border-gray-200 py-2">

    <!-- Search -->
    <div class="px-3 pb-2">
      <input type="text"
             data-organization-switcher-target="search"
             data-action="input->organization-switcher#filter"
             placeholder="Search organizations..."
             class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md">
    </div>

    <!-- Organizations List -->
    <div class="max-h-64 overflow-y-auto">
      <% current_user.organizations.each do |org| %>
        <%= button_to switch_organization_path(org),
            method: :patch,
            data: {
              turbo: true,
              organization_switcher_target: "item",
              organization_name: org.name.downcase
            },
            class: "w-full text-left px-3 py-2 hover:bg-gray-50 flex items-center justify-between group" do %>

          <div class="flex items-center space-x-3">
            <% if org.logo_url.present? %>
              <%= image_tag org.logo_url, class: "w-8 h-8 rounded" %>
            <% else %>
              <div class="w-8 h-8 bg-gray-300 rounded flex items-center justify-center">
                <span class="text-gray-600 text-sm font-bold">
                  <%= org.name[0].upcase %>
                </span>
              </div>
            <% end %>

            <div>
              <div class="font-medium text-gray-900">
                <%= org.name %>
              </div>
              <div class="text-xs text-gray-500">
                <%= pluralize(org.users.count, 'member') %>
              </div>
            </div>
          </div>

          <% if org == current_organization %>
            <svg class="w-5 h-5 text-indigo-600" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" />
            </svg>
          <% end %>
        <% end %>
      <% end %>
    </div>

    <!-- Create New Organization -->
    <div class="border-t border-gray-200 mt-2 pt-2">
      <%= link_to new_organization_path,
          class: "w-full px-3 py-2 hover:bg-gray-50 flex items-center space-x-2 text-gray-700" do %>
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
        </svg>
        <span class="text-sm font-medium">Create Organization</span>
      <% end %>
    </div>

    <!-- Organization Settings -->
    <% if current_user.role_in(current_organization).in?(['owner', 'admin']) %>
      <%= link_to organization_settings_path(current_organization),
          class: "w-full px-3 py-2 hover:bg-gray-50 flex items-center space-x-2 text-gray-700" do %>
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        <span class="text-sm font-medium">Organization Settings</span>
      <% end %>
    </div>
  </div>
</div>
```

## Stimulus Controller
```javascript
// app/javascript/controllers/organization_switcher_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "search", "item"]

  connect() {
    // Close on outside click
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)

    // Keyboard shortcuts
    this.handleKeyboard = this.handleKeyboard.bind(this)
    document.addEventListener("keydown", this.handleKeyboard)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeyboard)
    document.removeEventListener("click", this.closeOnOutsideClick)
  }

  toggle(event) {
    event.stopPropagation()

    if (this.dropdownTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.dropdownTarget.classList.remove("hidden")
    document.addEventListener("click", this.closeOnOutsideClick)

    // Focus search
    if (this.hasSearchTarget) {
      this.searchTarget.focus()
    }
  }

  close() {
    this.dropdownTarget.classList.add("hidden")
    document.removeEventListener("click", this.closeOnOutsideClick)

    // Reset search
    if (this.hasSearchTarget) {
      this.searchTarget.value = ""
      this.filter()
    }
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  filter() {
    const query = this.searchTarget.value.toLowerCase()

    this.itemTargets.forEach(item => {
      const name = item.dataset.organizationName
      if (name.includes(query)) {
        item.classList.remove("hidden")
      } else {
        item.classList.add("hidden")
      }
    })
  }

  handleKeyboard(event) {
    // Cmd/Ctrl + K to open switcher
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      this.open()
    }

    // Escape to close
    if (event.key === "Escape" && !this.dropdownTarget.classList.contains("hidden")) {
      this.close()
    }
  }
}
```

## Organization Guards

### Before Actions
```ruby
class ProjectsController < ApplicationController
  include OrganizationScoped

  def index
    @projects = scope_to_organization(Project).includes(:client)
  end
end

class TimeEntriesController < ApplicationController
  include OrganizationScoped

  def index
    @time_entries = current_user.time_entries
                                 .joins(:project)
                                 .where(projects: { organization: current_organization })
  end
end
```

## Session Management

### Organization Switching Controller
```ruby
class OrganizationSwitcherController < ApplicationController
  before_action :authenticate_user!

  def switch
    organization = current_user.organizations.find(params[:id])

    if current_user.switch_organization!(organization)
      redirect_to dashboard_path, notice: "Switched to #{organization.name}"
    else
      redirect_back fallback_location: dashboard_path,
                    alert: "Could not switch organization"
    end
  end
end
```

## Performance Considerations

1. **Eager Loading**: Always eager load organization relationships
2. **Caching**: Cache current organization in session/Redis
3. **Database Indexes**: Ensure proper indexes on foreign keys
4. **N+1 Prevention**: Use includes/joins for organization data

## Security Considerations

1. **Authorization**: Always check organization membership before data access
2. **Scoping**: Every query must be scoped to current organization
3. **Invitation Tokens**: Use secure random tokens with expiration
4. **Audit Logging**: Track organization switches and access

## Testing Strategy

1. **Unit Tests**: Model methods for organization management
2. **Integration Tests**: Organization switching flow
3. **System Tests**: Full user journey with multiple organizations
4. **Security Tests**: Ensure data isolation between organizations