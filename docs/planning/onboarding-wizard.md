# Onboarding Wizard - Multi-Step Modal Experience

## Overview
A beautiful, animated multi-step modal wizard that guides new users through organization setup. This wizard is **mandatory** for users without an organization and creates a delightful first experience.

## User Flow

### Entry Points
1. **New User Registration**: Immediately after account creation
2. **OAuth First Login**: After successful Google OAuth
3. **Invited User**: After accepting an invitation without existing account
4. **Manual Trigger**: From user settings if no organization exists

### Exit Prevention
- Modal cannot be dismissed with ESC or backdrop click
- No close button until completion
- Browser back button is intercepted
- Session stores onboarding state

## Wizard Steps

### Step 1: Welcome & Choice
**Purpose**: Warm welcome and organization type selection

```erb
<!-- app/views/onboarding/_step_welcome.html.erb -->
<div class="text-center">
  <div class="mb-8">
    <div class="mx-auto w-24 h-24 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-full flex items-center justify-center">
      <svg class="w-12 h-12 text-white" fill="none" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
      </svg>
    </div>
  </div>

  <h2 class="text-3xl font-bold text-gray-900 mb-2">
    Welcome to OnePunch, <%= current_user.first_name %>! 👋
  </h2>

  <p class="text-lg text-gray-600 mb-8">
    Let's get your workspace set up in less than 60 seconds.
  </p>

  <div class="grid grid-cols-1 md:grid-cols-2 gap-4 max-w-2xl mx-auto">
    <button data-action="click->onboarding-wizard#selectPath"
            data-path="create"
            class="p-6 border-2 border-gray-200 rounded-xl hover:border-indigo-500 hover:shadow-lg transition-all group">
      <div class="w-16 h-16 bg-indigo-100 rounded-lg flex items-center justify-center mb-4 mx-auto group-hover:bg-indigo-500 transition-colors">
        <svg class="w-8 h-8 text-indigo-600 group-hover:text-white" fill="none" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
        </svg>
      </div>
      <h3 class="text-lg font-semibold text-gray-900 mb-2">Create New Organization</h3>
      <p class="text-sm text-gray-600">Start fresh with your own workspace</p>
    </button>

    <button data-action="click->onboarding-wizard#selectPath"
            data-path="join"
            class="p-6 border-2 border-gray-200 rounded-xl hover:border-indigo-500 hover:shadow-lg transition-all group">
      <div class="w-16 h-16 bg-green-100 rounded-lg flex items-center justify-center mb-4 mx-auto group-hover:bg-green-500 transition-colors">
        <svg class="w-8 h-8 text-green-600 group-hover:text-white" fill="none" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
      </div>
      <h3 class="text-lg font-semibold text-gray-900 mb-2">Join Existing Team</h3>
      <p class="text-sm text-gray-600">Enter an invitation code from your team</p>
    </button>
  </div>
</div>
```

### Step 2A: Create Organization
**Purpose**: Gather organization details

```erb
<!-- app/views/onboarding/_step_create_organization.html.erb -->
<div>
  <h2 class="text-2xl font-bold text-gray-900 mb-6">
    Set up your organization
  </h2>

  <%= form_with model: @organization,
                url: onboarding_organization_path,
                data: {
                  controller: "form-validation",
                  action: "submit->onboarding-wizard#submitOrganization"
                } do |f| %>

    <div class="space-y-6">
      <!-- Organization Name -->
      <div>
        <%= f.label :name, class: "block text-sm font-medium text-gray-700 mb-2" %>
        <%= f.text_field :name,
            placeholder: "Acme Inc",
            required: true,
            data: { validation_target: "field" },
            class: "w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500" %>
        <p class="mt-1 text-xs text-gray-500">This is how your team will identify your workspace</p>
      </div>

      <!-- Organization Size -->
      <div>
        <%= f.label :size, "Team Size", class: "block text-sm font-medium text-gray-700 mb-2" %>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
          <% [
            ['solo', 'Just me', '👤'],
            ['small', '2-10', '👥'],
            ['medium', '11-50', '👥👥'],
            ['large', '50+', '🏢']
          ].each do |value, label, emoji| %>
            <label class="relative">
              <%= f.radio_button :size, value,
                  class: "peer sr-only",
                  data: { action: "change->form-validation#validate" } %>
              <div class="p-4 border-2 border-gray-200 rounded-lg cursor-pointer text-center
                          peer-checked:border-indigo-500 peer-checked:bg-indigo-50
                          hover:border-gray-300 transition-all">
                <div class="text-2xl mb-1"><%= emoji %></div>
                <div class="text-sm font-medium text-gray-900"><%= label %></div>
              </div>
            </label>
          <% end %>
        </div>
      </div>

      <!-- Industry -->
      <div>
        <%= f.label :industry, class: "block text-sm font-medium text-gray-700 mb-2" %>
        <%= f.select :industry,
            options_for_select([
              ['Technology', 'technology'],
              ['Marketing & Advertising', 'marketing'],
              ['Design & Creative', 'design'],
              ['Consulting', 'consulting'],
              ['Healthcare', 'healthcare'],
              ['Education', 'education'],
              ['Finance', 'finance'],
              ['Non-profit', 'nonprofit'],
              ['Other', 'other']
            ]),
            { prompt: 'Select your industry' },
            class: "w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500" %>
      </div>

      <!-- Logo Upload (Optional) -->
      <div>
        <%= f.label :logo, "Organization Logo (Optional)",
            class: "block text-sm font-medium text-gray-700 mb-2" %>

        <div class="flex items-center space-x-4">
          <div data-controller="avatar-upload"
               class="relative">
            <div data-avatar-upload-target="preview"
                 class="w-20 h-20 bg-gray-100 rounded-lg flex items-center justify-center overflow-hidden">
              <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>

            <%= f.file_field :logo,
                accept: "image/*",
                data: {
                  avatar_upload_target: "input",
                  action: "change->avatar-upload#preview"
                },
                class: "sr-only" %>

            <button type="button"
                    data-action="click->avatar-upload#trigger"
                    class="absolute -bottom-1 -right-1 w-7 h-7 bg-indigo-600 rounded-full flex items-center justify-center hover:bg-indigo-700">
              <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
            </button>
          </div>

          <div class="text-sm text-gray-600">
            <p>Upload a logo to personalize your workspace</p>
            <p class="text-xs text-gray-500">PNG, JPG up to 2MB</p>
          </div>
        </div>
      </div>
    </div>
  <% end %>
</div>
```

### Step 2B: Join Organization (Alternative)
**Purpose**: Enter invitation code

```erb
<!-- app/views/onboarding/_step_join_organization.html.erb -->
<div>
  <h2 class="text-2xl font-bold text-gray-900 mb-6">
    Join your team
  </h2>

  <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
    <div class="flex">
      <svg class="w-5 h-5 text-blue-600 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
      </svg>
      <p class="ml-3 text-sm text-blue-800">
        Ask your team administrator for an invitation code
      </p>
    </div>
  </div>

  <%= form_with url: join_organization_path,
                data: { controller: "invitation-code" } do |f| %>

    <div>
      <label class="block text-sm font-medium text-gray-700 mb-2">
        Invitation Code
      </label>

      <div class="flex space-x-2">
        <% 6.times do |i| %>
          <input type="text"
                 maxlength="1"
                 data-invitation-code-target="input"
                 data-action="input->invitation-code#handleInput"
                 data-index="<%= i %>"
                 class="w-12 h-12 text-center text-xl font-mono border-2 border-gray-300 rounded-lg
                        focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500">
        <% end %>
      </div>

      <input type="hidden"
             name="invitation_code"
             data-invitation-code-target="hidden">
    </div>

    <div data-invitation-code-target="preview"
         class="hidden mt-6 p-4 bg-green-50 border border-green-200 rounded-lg">
      <h3 class="font-semibold text-green-900 mb-2">You're invited to join:</h3>
      <div class="flex items-center space-x-3">
        <div data-invitation-code-target="orgLogo"
             class="w-12 h-12 bg-gray-200 rounded-lg"></div>
        <div>
          <p data-invitation-code-target="orgName"
             class="font-semibold text-gray-900"></p>
          <p data-invitation-code-target="invitedBy"
             class="text-sm text-gray-600"></p>
        </div>
      </div>
    </div>

  <% end %>
</div>
```

### Step 3: Invite Team Members
**Purpose**: Optional team invitations

```erb
<!-- app/views/onboarding/_step_invite_team.html.erb -->
<div>
  <h2 class="text-2xl font-bold text-gray-900 mb-2">
    Invite your team
  </h2>
  <p class="text-gray-600 mb-6">
    Collaborate better by inviting your team members (you can skip this for now)
  </p>

  <div data-controller="team-invites">
    <div data-team-invites-target="container" class="space-y-3">
      <!-- Invite Row Template -->
      <div data-team-invites-target="template" class="hidden">
        <div class="flex space-x-3">
          <input type="email"
                 placeholder="colleague@example.com"
                 class="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500">

          <select class="px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500">
            <option value="member">Member</option>
            <option value="admin">Admin</option>
          </select>

          <button type="button"
                  data-action="click->team-invites#remove"
                  class="p-3 text-red-600 hover:bg-red-50 rounded-lg">
            <svg class="w-5 h-5" fill="none" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
          </button>
        </div>
      </div>

      <!-- Initial invite rows -->
      <div class="flex space-x-3">
        <input type="email"
               name="invites[][email]"
               placeholder="colleague@example.com"
               class="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500">

        <select name="invites[][role]"
                class="px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500">
          <option value="member">Member</option>
          <option value="admin">Admin</option>
        </select>
      </div>
    </div>

    <button type="button"
            data-action="click->team-invites#add"
            class="mt-4 w-full py-3 border-2 border-dashed border-gray-300 rounded-lg text-gray-600 hover:border-gray-400 hover:text-gray-700 transition-colors">
      <svg class="w-5 h-5 inline mr-2" fill="none" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
      </svg>
      Add another team member
    </button>
  </div>

  <!-- Copy Invitation Link -->
  <div class="mt-8 p-4 bg-gray-50 rounded-lg">
    <h4 class="text-sm font-semibold text-gray-900 mb-2">Or share this link</h4>
    <div class="flex space-x-2">
      <input type="text"
             readonly
             value="<%= invitation_url(@organization) %>"
             data-controller="clipboard"
             data-clipboard-target="source"
             class="flex-1 px-3 py-2 bg-white border border-gray-300 rounded text-sm font-mono">

      <button type="button"
              data-action="click->clipboard#copy"
              class="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 transition-colors">
        Copy Link
      </button>
    </div>
  </div>
</div>
```

### Step 4: First Project Setup
**Purpose**: Create first project to get started

```erb
<!-- app/views/onboarding/_step_first_project.html.erb -->
<div>
  <h2 class="text-2xl font-bold text-gray-900 mb-2">
    Create your first project
  </h2>
  <p class="text-gray-600 mb-6">
    Projects help you organize and track time for different clients or tasks
  </p>

  <%= form_with model: @project,
                url: onboarding_project_path do |f| %>

    <div class="space-y-6">
      <!-- Project Name -->
      <div>
        <%= f.label :name, class: "block text-sm font-medium text-gray-700 mb-2" %>
        <%= f.text_field :name,
            placeholder: "Website Redesign",
            required: true,
            class: "w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500" %>
      </div>

      <!-- Project Color -->
      <div>
        <%= f.label :color, "Project Color",
            class: "block text-sm font-medium text-gray-700 mb-2" %>
        <div class="flex space-x-2">
          <% %w[#3B82F6 #10B981 #F59E0B #EF4444 #8B5CF6 #EC4899 #6B7280].each do |color| %>
            <label class="relative">
              <%= f.radio_button :color, color, class: "peer sr-only" %>
              <div class="w-10 h-10 rounded-lg cursor-pointer ring-offset-2 transition-all
                          peer-checked:ring-2 peer-checked:ring-offset-2 peer-checked:ring-gray-400
                          hover:scale-110"
                   style="background-color: <%= color %>">
              </div>
            </label>
          <% end %>
        </div>
      </div>

      <!-- Hourly Rate -->
      <div>
        <%= f.label :hourly_rate, "Hourly Rate (Optional)",
            class: "block text-sm font-medium text-gray-700 mb-2" %>
        <div class="relative">
          <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <span class="text-gray-500 sm:text-sm">$</span>
          </div>
          <%= f.number_field :hourly_rate,
              step: 0.01,
              placeholder: "150.00",
              class: "w-full pl-8 pr-12 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500" %>
          <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
            <span class="text-gray-500 sm:text-sm">/ hour</span>
          </div>
        </div>
        <p class="mt-1 text-xs text-gray-500">Used for invoicing and revenue tracking</p>
      </div>

      <!-- Quick Templates -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">
          Or choose a template
        </label>
        <div class="grid grid-cols-2 gap-3">
          <% [
            ['Client Work', '💼'],
            ['Internal', '🏢'],
            ['Personal', '👤'],
            ['Learning', '📚']
          ].each do |template, emoji| %>
            <button type="button"
                    data-action="click->onboarding-wizard#applyTemplate"
                    data-template="<%= template.downcase.gsub(' ', '_') %>"
                    class="p-4 border border-gray-200 rounded-lg hover:border-indigo-500 hover:bg-indigo-50 transition-all">
              <div class="text-2xl mb-1"><%= emoji %></div>
              <div class="text-sm font-medium text-gray-900"><%= template %></div>
            </button>
          <% end %>
        </div>
      </div>
    </div>
  <% end %>
</div>
```

### Step 5: Success & Tour
**Purpose**: Celebrate and offer guided tour

```erb
<!-- app/views/onboarding/_step_success.html.erb -->
<div class="text-center">
  <div class="mb-8">
    <!-- Animated Success Icon -->
    <div class="mx-auto w-24 h-24 bg-green-100 rounded-full flex items-center justify-center animate-bounce">
      <svg class="w-12 h-12 text-green-600" fill="none" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
      </svg>
    </div>
  </div>

  <h2 class="text-3xl font-bold text-gray-900 mb-2">
    You're all set! 🎉
  </h2>

  <p class="text-lg text-gray-600 mb-8">
    Your workspace is ready. Let's start tracking time!
  </p>

  <!-- Quick Stats -->
  <div class="grid grid-cols-3 gap-4 max-w-md mx-auto mb-8">
    <div class="bg-gray-50 rounded-lg p-4">
      <div class="text-2xl font-bold text-gray-900">1</div>
      <div class="text-xs text-gray-600">Organization</div>
    </div>
    <div class="bg-gray-50 rounded-lg p-4">
      <div class="text-2xl font-bold text-gray-900"><%= @invites_sent %></div>
      <div class="text-xs text-gray-600">Invites Sent</div>
    </div>
    <div class="bg-gray-50 rounded-lg p-4">
      <div class="text-2xl font-bold text-gray-900">1</div>
      <div class="text-xs text-gray-600">Project Ready</div>
    </div>
  </div>

  <!-- Action Buttons -->
  <div class="space-y-3">
    <button data-action="click->onboarding-wizard#startTour"
            class="w-full px-6 py-3 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors font-medium">
      Take a Quick Tour (30 seconds)
    </button>

    <button data-action="click->onboarding-wizard#skipTour"
            class="w-full px-6 py-3 bg-white text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors font-medium">
      Skip to Dashboard
    </button>
  </div>

  <!-- Pro Tips -->
  <div class="mt-8 p-4 bg-blue-50 rounded-lg text-left">
    <h4 class="text-sm font-semibold text-blue-900 mb-2">💡 Pro Tips</h4>
    <ul class="space-y-1 text-sm text-blue-800">
      <li>• Press <kbd class="px-2 py-1 bg-blue-100 rounded">Space</kbd> to start/stop timer</li>
      <li>• Use <kbd class="px-2 py-1 bg-blue-100 rounded">Cmd+K</kbd> to switch organizations</li>
      <li>• Install our mobile app for time tracking on the go</li>
    </ul>
  </div>
</div>
```

## Modal Container & Controls

```erb
<!-- app/views/onboarding/wizard.html.erb -->
<div data-controller="onboarding-wizard"
     data-onboarding-wizard-current-step-value="1"
     data-onboarding-wizard-total-steps-value="5"
     class="fixed inset-0 z-50 overflow-y-auto">

  <!-- Backdrop -->
  <div class="fixed inset-0 bg-gray-900 bg-opacity-75 transition-opacity"
       data-onboarding-wizard-target="backdrop"></div>

  <!-- Modal -->
  <div class="flex min-h-full items-center justify-center p-4">
    <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-2xl transform transition-all"
         data-onboarding-wizard-target="modal">

      <!-- Progress Bar -->
      <div class="absolute top-0 left-0 right-0 h-1 bg-gray-200 rounded-t-2xl overflow-hidden">
        <div data-onboarding-wizard-target="progressBar"
             class="h-full bg-gradient-to-r from-indigo-500 to-purple-600 transition-all duration-500"
             style="width: 20%"></div>
      </div>

      <!-- Step Counter -->
      <div class="flex justify-between items-center px-8 pt-6 pb-4 border-b border-gray-100">
        <div class="text-sm text-gray-500">
          Step <span data-onboarding-wizard-target="currentStep">1</span> of 5
        </div>

        <!-- Step Dots -->
        <div class="flex space-x-2">
          <% 5.times do |i| %>
            <div data-onboarding-wizard-target="dot"
                 data-step="<%= i + 1 %>"
                 class="w-2 h-2 rounded-full transition-all
                        <%= i == 0 ? 'bg-indigo-600 w-8' : 'bg-gray-300' %>">
            </div>
          <% end %>
        </div>
      </div>

      <!-- Step Content -->
      <div class="px-8 py-6">
        <div data-onboarding-wizard-target="stepContainer">
          <!-- Steps are loaded here dynamically -->
        </div>
      </div>

      <!-- Navigation -->
      <div class="flex justify-between items-center px-8 py-6 border-t border-gray-100">
        <button data-action="click->onboarding-wizard#previousStep"
                data-onboarding-wizard-target="backButton"
                class="hidden px-6 py-2 text-gray-600 hover:text-gray-900 transition-colors">
          ← Back
        </button>

        <div class="ml-auto flex space-x-3">
          <button data-action="click->onboarding-wizard#skip"
                  data-onboarding-wizard-target="skipButton"
                  class="px-6 py-2 text-gray-500 hover:text-gray-700 transition-colors">
            Skip
          </button>

          <button data-action="click->onboarding-wizard#nextStep"
                  data-onboarding-wizard-target="nextButton"
                  class="px-8 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors font-medium">
            Continue →
          </button>
        </div>
      </div>
    </div>
  </div>
</div>
```

## Stimulus Controller

```javascript
// app/javascript/controllers/onboarding_wizard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "backdrop", "modal", "stepContainer", "progressBar",
    "currentStep", "dot", "backButton", "skipButton", "nextButton"
  ]

  static values = {
    currentStep: Number,
    totalSteps: Number,
    path: String // 'create' or 'join'
  }

  connect() {
    // Prevent ESC key
    this.preventEscape = this.preventEscape.bind(this)
    document.addEventListener("keydown", this.preventEscape)

    // Load first step
    this.loadStep(1)

    // Animate entrance
    this.animateIn()
  }

  disconnect() {
    document.removeEventListener("keydown", this.preventEscape)
  }

  preventEscape(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.shakeModal()
    }
  }

  shakeModal() {
    this.modalTarget.classList.add("animate-shake")
    setTimeout(() => {
      this.modalTarget.classList.remove("animate-shake")
    }, 500)
  }

  animateIn() {
    // Fade in backdrop
    this.backdropTarget.style.opacity = "0"
    setTimeout(() => {
      this.backdropTarget.style.opacity = "1"
    }, 10)

    // Scale in modal
    this.modalTarget.style.transform = "scale(0.9)"
    this.modalTarget.style.opacity = "0"
    setTimeout(() => {
      this.modalTarget.style.transform = "scale(1)"
      this.modalTarget.style.opacity = "1"
    }, 100)
  }

  selectPath(event) {
    this.pathValue = event.currentTarget.dataset.path
    this.nextStep()
  }

  async loadStep(stepNumber) {
    const response = await fetch(`/onboarding/step/${stepNumber}?path=${this.pathValue}`, {
      headers: {
        "Accept": "text/html"
      }
    })

    const html = await response.text()
    this.stepContainerTarget.innerHTML = html

    // Animate step transition
    this.stepContainerTarget.style.opacity = "0"
    this.stepContainerTarget.style.transform = "translateX(20px)"

    setTimeout(() => {
      this.stepContainerTarget.style.opacity = "1"
      this.stepContainerTarget.style.transform = "translateX(0)"
    }, 100)

    this.updateUI()
  }

  updateUI() {
    // Update progress
    const progress = (this.currentStepValue / this.totalStepsValue) * 100
    this.progressBarTarget.style.width = `${progress}%`

    // Update step counter
    this.currentStepTarget.textContent = this.currentStepValue

    // Update dots
    this.dotTargets.forEach((dot, index) => {
      if (index < this.currentStepValue - 1) {
        dot.classList.add("bg-indigo-600")
        dot.classList.remove("bg-gray-300", "w-8")
        dot.classList.add("w-2")
      } else if (index === this.currentStepValue - 1) {
        dot.classList.add("bg-indigo-600", "w-8")
        dot.classList.remove("bg-gray-300", "w-2")
      } else {
        dot.classList.add("bg-gray-300", "w-2")
        dot.classList.remove("bg-indigo-600", "w-8")
      }
    })

    // Show/hide buttons
    this.backButtonTarget.classList.toggle("hidden", this.currentStepValue === 1)
    this.skipButtonTarget.classList.toggle("hidden", this.currentStepValue === this.totalStepsValue)

    // Update next button text
    if (this.currentStepValue === this.totalStepsValue) {
      this.nextButtonTarget.textContent = "Get Started →"
    } else {
      this.nextButtonTarget.textContent = "Continue →"
    }
  }

  nextStep() {
    if (this.currentStepValue < this.totalStepsValue) {
      this.currentStepValue++
      this.loadStep(this.currentStepValue)
    } else {
      this.complete()
    }
  }

  previousStep() {
    if (this.currentStepValue > 1) {
      this.currentStepValue--
      this.loadStep(this.currentStepValue)
    }
  }

  skip() {
    if (confirm("Are you sure you want to skip setup? You can complete it later from settings.")) {
      // Jump to last step
      this.currentStepValue = this.totalStepsValue
      this.loadStep(this.currentStepValue)
    }
  }

  async complete() {
    // Submit final data
    const response = await fetch("/onboarding/complete", {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        completed_at: new Date().toISOString()
      })
    })

    if (response.ok) {
      // Redirect to dashboard with celebration
      window.location.href = "/dashboard?onboarding_complete=true"
    }
  }

  startTour() {
    window.location.href = "/dashboard?tour=true"
  }

  skipTour() {
    window.location.href = "/dashboard"
  }
}
```

## CSS Animations

```css
/* app/assets/stylesheets/onboarding.css */

@keyframes shake {
  0%, 100% { transform: translateX(0); }
  10%, 30%, 50%, 70%, 90% { transform: translateX(-10px); }
  20%, 40%, 60%, 80% { transform: translateX(10px); }
}

.animate-shake {
  animation: shake 0.5s;
}

/* Smooth transitions */
[data-onboarding-wizard-target="stepContainer"] {
  transition: opacity 0.3s, transform 0.3s;
}

[data-onboarding-wizard-target="progressBar"] {
  transition: width 0.5s ease-out;
}

[data-onboarding-wizard-target="dot"] {
  transition: all 0.3s;
}

/* Keyboard hints */
kbd {
  background: linear-gradient(180deg, #f9f9f9 0%, #e9e9e9 100%);
  border: 1px solid #c9c9c9;
  border-radius: 4px;
  box-shadow: 0 1px 0 #c9c9c9;
  font-family: monospace;
  font-size: 0.875rem;
  padding: 2px 6px;
}
```

## Controller Actions

```ruby
class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_onboarded, except: [:complete]
  layout 'onboarding'

  def wizard
    @organization = Organization.new
    @project = Project.new
  end

  def step
    @step_number = params[:step].to_i
    @path = params[:path]

    render partial: "step_#{step_name}", layout: false
  end

  def create_organization
    @organization = Organization.new(organization_params)
    @organization.users << current_user

    if @organization.save
      current_user.update!(current_organization: @organization)
      Membership.create!(
        user: current_user,
        organization: @organization,
        role: 'owner'
      )
      render json: { success: true, next_step: 3 }
    else
      render json: {
        success: false,
        errors: @organization.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def invite_members
    invites = params[:invites] || []

    invites.each do |invite|
      next if invite[:email].blank?

      Invitation.create!(
        organization: current_organization,
        email: invite[:email],
        role: invite[:role],
        invited_by: current_user,
        expires_at: 7.days.from_now
      )

      # Send invitation email
      InvitationMailer.invite(invitation).deliver_later
    end

    render json: { success: true, invites_sent: invites.size }
  end

  def create_project
    @project = current_organization.projects.build(project_params)

    if @project.save
      render json: { success: true, next_step: 5 }
    else
      render json: {
        success: false,
        errors: @project.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def complete
    current_organization.complete_onboarding!
    redirect_to dashboard_path, notice: "Welcome to OnePunch!"
  end

  private

  def redirect_if_onboarded
    if current_user.current_organization&.onboarded?
      redirect_to dashboard_path
    end
  end

  def step_name
    case @step_number
    when 1 then 'welcome'
    when 2
      @path == 'join' ? 'join_organization' : 'create_organization'
    when 3 then 'invite_team'
    when 4 then 'first_project'
    when 5 then 'success'
    end
  end

  def organization_params
    params.require(:organization).permit(
      :name, :size, :industry, :logo, :website
    )
  end

  def project_params
    params.require(:project).permit(
      :name, :color, :hourly_rate, :description
    )
  end
end
```

## Testing the Wizard

1. **New User Flow**: Sign up → Immediate redirect to wizard
2. **OAuth User**: Google sign-in → Check for org → Wizard if none
3. **Invited User**: Accept invite → Join org step prefilled
4. **Completion**: All data saved → Dashboard with tour prompt

## Accessibility

- Full keyboard navigation
- ARIA labels and roles
- Focus management between steps
- Screen reader announcements
- High contrast mode support

## Mobile Responsiveness

- Full-screen modal on mobile
- Touch-friendly buttons
- Swipe gestures for navigation
- Responsive form layouts
- Optimized for small screens