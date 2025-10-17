# TODO 01: MVP Launch - OnePunch Time Tracking & Invoicing

## 🎯 Goal: Launch MVP Today with Core Features

### Phase 1: Authentication & User Management (1-2 hours)

#### Models & Migrations

- [ ] Generate User model
```bash
rails g model User email:string:uniq first_name:string last_name:string password_digest:string google_uid:string avatar_url:string role:integer last_sign_in_at:datetime
```

- [ ] Generate Organization model
```bash
rails g model Organization name:string:uniq slug:string:uniq billing_email:string address:text tax_id:string currency:string timezone:string
```

- [ ] Generate Membership model (join table)
```bash
rails g model Membership user:references organization:references role:integer joined_at:datetime
```

- [ ] Add indexes and constraints
```ruby
# In migrations:
add_index :users, :email, unique: true
add_index :users, :google_uid, unique: true, where: "google_uid IS NOT NULL"
add_index :organizations, :slug, unique: true
add_index :memberships, [:user_id, :organization_id], unique: true
```

#### Authentication Controllers

- [ ] Generate authentication controllers
```bash
rails g controller Sessions new create destroy
rails g controller Registrations new create
rails g controller PasswordResets new create edit update
rails g controller OauthCallbacks
```

- [ ] Implement SessionsController
```ruby
class SessionsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.authenticate_by(email: params[:email], password: params[:password])
    if @user
      login @user
      redirect_to dashboard_path, notice: "Welcome back!"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
    redirect_to root_path, notice: "Logged out successfully"
  end
end
```

- [ ] Google OAuth configuration
```ruby
# config/initializers/omniauth.rb
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    ENV['GOOGLE_CLIENT_ID'],
    ENV['GOOGLE_CLIENT_SECRET'],
    {
      scope: 'email,profile',
      prompt: 'select_account',
      image_aspect_ratio: 'square',
      image_size: 200
    }
end
```

### Phase 2: Core Business Models (1 hour)

#### Project & Time Tracking Models

- [ ] Generate Project model
```bash
rails g model Project organization:references name:string description:text hourly_rate:decimal status:integer color:string archived:boolean
```

- [ ] Generate Client model
```bash
rails g model Client organization:references name:string email:string company:string phone:string address:text tax_id:string
```

- [ ] Generate TimeEntry model
```bash
rails g model TimeEntry user:references project:references description:text started_at:datetime ended_at:datetime duration:integer billable:boolean billed:boolean
```

- [ ] Generate Tag model (for categorizing time entries)
```bash
rails g model Tag organization:references name:string color:string
rails g model Tagging time_entry:references tag:references
```

#### Invoice Models

- [ ] Generate Invoice model
```bash
rails g model Invoice organization:references client:references project:references number:string status:integer issued_at:date due_at:date paid_at:date subtotal:decimal tax_rate:decimal tax_amount:decimal total:decimal notes:text
```

- [ ] Generate InvoiceLineItem model
```bash
rails g model InvoiceLineItem invoice:references description:text quantity:decimal unit_price:decimal amount:decimal time_entry_ids:text
```

### Phase 3: Core Features Implementation (2-3 hours)

#### Time Tracking

- [ ] Timer Controller
```ruby
class TimerController < ApplicationController
  before_action :authenticate_user!
  
  def start
    @time_entry = current_user.time_entries.create!(
      project_id: params[:project_id],
      started_at: Time.current,
      description: params[:description]
    )
    
    broadcast_timer_update
    render json: { id: @time_entry.id, started_at: @time_entry.started_at }
  end
  
  def stop
    @time_entry = current_user.time_entries.find(params[:id])
    @time_entry.stop!
    
    broadcast_timer_update
    render json: { id: @time_entry.id, duration: @time_entry.duration }
  end
  
  private
  
  def broadcast_timer_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "timer_#{current_user.id}",
      target: "timer_status",
      partial: "timer/status",
      locals: { user: current_user }
    )
  end
end
```

- [ ] Stimulus Timer Controller
```javascript
// app/javascript/controllers/timer_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "startBtn", "stopBtn", "projectSelect"]
  static values = { 
    running: Boolean,
    startTime: String,
    entryId: Number
  }
  
  connect() {
    if (this.runningValue) {
      this.startTimer()
    }
  }
  
  start() {
    const projectId = this.projectSelectTarget.value
    if (!projectId) {
      alert("Please select a project")
      return
    }
    
    fetch('/timer/start', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ project_id: projectId })
    })
    .then(response => response.json())
    .then(data => {
      this.runningValue = true
      this.startTimeValue = data.started_at
      this.entryIdValue = data.id
      this.startTimer()
    })
  }
  
  stop() {
    fetch(`/timer/stop/${this.entryIdValue}`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      this.runningValue = false
      this.stopTimer()
    })
  }
  
  startTimer() {
    this.updateDisplay()
    this.timer = setInterval(() => {
      this.updateDisplay()
    }, 1000)
    
    this.startBtnTarget.classList.add('hidden')
    this.stopBtnTarget.classList.remove('hidden')
  }
  
  stopTimer() {
    clearInterval(this.timer)
    this.displayTarget.textContent = "00:00:00"
    this.startBtnTarget.classList.remove('hidden')
    this.stopBtnTarget.classList.add('hidden')
  }
  
  updateDisplay() {
    const start = new Date(this.startTimeValue)
    const now = new Date()
    const diff = Math.floor((now - start) / 1000)
    
    const hours = Math.floor(diff / 3600).toString().padStart(2, '0')
    const minutes = Math.floor((diff % 3600) / 60).toString().padStart(2, '0')
    const seconds = (diff % 60).toString().padStart(2, '0')
    
    this.displayTarget.textContent = `${hours}:${minutes}:${seconds}`
  }
}
```

#### Dashboard Views

- [ ] Dashboard Controller
```ruby
class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @current_timer = current_user.time_entries.running.first
    @today_duration = current_user.time_entries.today.sum(:duration)
    @week_duration = current_user.time_entries.this_week.sum(:duration)
    @recent_entries = current_user.time_entries.recent.limit(10)
    @projects = current_organization.projects.active
  end
end
```

- [ ] Dashboard View
```erb
<!-- app/views/dashboard/index.html.erb -->
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <!-- Timer Widget -->
  <div class="bg-white rounded-lg shadow-md p-6 mb-8" data-controller="timer"
       data-timer-running-value="<%= @current_timer.present? %>"
       data-timer-start-time-value="<%= @current_timer&.started_at&.iso8601 %>"
       data-timer-entry-id-value="<%= @current_timer&.id %>">
    
    <h2 class="text-2xl font-bold mb-4">Time Tracker</h2>
    
    <div class="flex items-center space-x-4">
      <select data-timer-target="projectSelect" class="form-select">
        <option value="">Select Project...</option>
        <% @projects.each do |project| %>
          <option value="<%= project.id %>"><%= project.name %></option>
        <% end %>
      </select>
      
      <div data-timer-target="display" class="text-3xl font-mono">
        00:00:00
      </div>
      
      <button data-timer-target="startBtn" 
              data-action="click->timer#start"
              class="bg-green-500 text-white px-6 py-2 rounded">
        Start
      </button>
      
      <button data-timer-target="stopBtn" 
              data-action="click->timer#stop"
              class="hidden bg-red-500 text-white px-6 py-2 rounded">
        Stop
      </button>
    </div>
  </div>
  
  <!-- Stats Cards -->
  <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
    <div class="bg-white rounded-lg shadow p-6">
      <h3 class="text-gray-600 text-sm">Today</h3>
      <p class="text-2xl font-bold"><%= format_duration(@today_duration) %></p>
    </div>
    
    <div class="bg-white rounded-lg shadow p-6">
      <h3 class="text-gray-600 text-sm">This Week</h3>
      <p class="text-2xl font-bold"><%= format_duration(@week_duration) %></p>
    </div>
    
    <div class="bg-white rounded-lg shadow p-6">
      <h3 class="text-gray-600 text-sm">Active Projects</h3>
      <p class="text-2xl font-bold"><%= @projects.count %></p>
    </div>
  </div>
  
  <!-- Recent Time Entries -->
  <div class="bg-white rounded-lg shadow">
    <div class="px-6 py-4 border-b">
      <h3 class="text-lg font-semibold">Recent Time Entries</h3>
    </div>
    
    <div class="divide-y">
      <% @recent_entries.each do |entry| %>
        <div class="px-6 py-4 hover:bg-gray-50">
          <div class="flex justify-between items-center">
            <div>
              <p class="font-medium"><%= entry.project.name %></p>
              <p class="text-sm text-gray-600"><%= entry.description %></p>
            </div>
            <div class="text-right">
              <p class="font-mono"><%= format_duration(entry.duration) %></p>
              <p class="text-sm text-gray-500"><%= entry.started_at.strftime("%b %d, %I:%M %p") %></p>
            </div>
          </div>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

### Phase 4: Real-time Features (1 hour)

#### Turbo Streams Setup

- [ ] Configure ActionCable for real-time updates
```yaml
# config/cable.yml
development:
  adapter: solid_cable
  
production:
  adapter: solid_cable
```

- [ ] Timer broadcast updates
```ruby
# app/models/time_entry.rb
class TimeEntry < ApplicationRecord
  belongs_to :user
  belongs_to :project
  
  scope :running, -> { where(ended_at: nil) }
  scope :today, -> { where(started_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(started_at: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :recent, -> { order(started_at: :desc) }
  
  after_create_commit -> { broadcast_prepend_to "time_entries" }
  after_update_commit -> { broadcast_replace_to "time_entries" }
  after_destroy_commit -> { broadcast_remove_to "time_entries" }
  
  def stop!
    self.ended_at = Time.current
    self.duration = (ended_at - started_at).to_i
    save!
  end
  
  def running?
    ended_at.nil?
  end
end
```

### Phase 5: Mobile Support (30 minutes)

#### PWA Configuration

- [ ] Update manifest.json
```json
{
  "name": "OnePunch Time Tracker",
  "short_name": "OnePunch",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#10b981",
  "icons": [
    {
      "src": "/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

- [ ] Service Worker for offline support
```javascript
// public/service-worker.js
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open('v1').then(cache => {
      return cache.addAll([
        '/',
        '/offline.html',
        '/icon-192.png'
      ])
    })
  )
})

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request).then(response => {
      return response || fetch(event.request)
    }).catch(() => {
      return caches.match('/offline.html')
    })
  )
})
```

#### Hotwire Native Bridge

- [ ] Create mobile navigation configuration
```ruby
# app/controllers/api/navigation_controller.rb
class Api::NavigationController < ApplicationController
  def show
    render json: {
      rules: [
        {
          patterns: ["/new$", "/edit$"],
          properties: {
            presentation: "modal"
          }
        }
      ]
    }
  end
end
```

### Phase 6: Basic Invoicing (1 hour)

#### Invoice Generation

- [ ] Invoice Controller
```ruby
class InvoicesController < ApplicationController
  before_action :authenticate_user!
  
  def new
    @invoice = current_organization.invoices.build
    @clients = current_organization.clients
    @projects = current_organization.projects
    @unbilled_entries = TimeEntry.unbilled.includes(:project)
  end
  
  def create
    @invoice = current_organization.invoices.build(invoice_params)
    
    if @invoice.save
      @invoice.generate_pdf!
      redirect_to @invoice, notice: "Invoice created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  private
  
  def invoice_params
    params.require(:invoice).permit(:client_id, :project_id, :due_at, :notes, 
                                   line_items_attributes: [:description, :quantity, :unit_price])
  end
end
```

- [ ] PDF Generation with Wicked PDF
```ruby
# app/models/invoice.rb
class Invoice < ApplicationRecord
  belongs_to :organization
  belongs_to :client
  belongs_to :project, optional: true
  has_many :line_items, class_name: "InvoiceLineItem", dependent: :destroy
  
  before_create :generate_number
  
  def generate_pdf!
    pdf = WickedPdf.new.pdf_from_string(
      ApplicationController.render(
        template: 'invoices/pdf',
        layout: 'pdf',
        locals: { invoice: self }
      )
    )
    
    # Save to ActiveStorage
    io = StringIO.new(pdf)
    self.pdf.attach(
      io: io,
      filename: "invoice_#{number}.pdf",
      content_type: "application/pdf"
    )
  end
  
  private
  
  def generate_number
    last_number = organization.invoices.maximum(:number)&.to_i || 0
    self.number = (last_number + 1).to_s.rjust(4, '0')
  end
end
```

### Phase 7: Deployment Prep (30 minutes)

#### Environment Setup

- [ ] Update production configuration
```ruby
# config/environments/production.rb
config.force_ssl = true
config.assume_ssl = true
config.action_mailer.default_url_options = { host: ENV['APP_HOST'] }
```

- [ ] Kamal configuration
```yaml
# config/deploy.yml
service: onepunch
image: onepunch
servers:
  - your.server.ip
registry:
  username: your-docker-username
  password:
    - DOCKER_REGISTRY_PASSWORD
env:
  clear:
    APP_HOST: onepunch.yourdomain.com
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - REDIS_URL
```

#### Database Seeds

- [ ] Create seed data
```ruby
# db/seeds.rb
# Create demo user
user = User.create!(
  email: "demo@onepunch.app",
  password: "password123",
  first_name: "Demo",
  last_name: "User"
)

# Create demo organization
org = Organization.create!(
  name: "Demo Company",
  slug: "demo-company"
)

# Create membership
Membership.create!(
  user: user,
  organization: org,
  role: "owner"
)

# Create demo projects
project1 = Project.create!(
  organization: org,
  name: "Website Redesign",
  hourly_rate: 100,
  color: "#10b981"
)

project2 = Project.create!(
  organization: org,
  name: "Mobile App Development",
  hourly_rate: 120,
  color: "#3b82f6"
)

# Create demo client
client = Client.create!(
  organization: org,
  name: "Acme Corp",
  email: "billing@acme.com"
)

puts "Seed data created successfully!"
```

## 🚀 Launch Checklist

### Pre-Launch (15 minutes)
- [ ] Run `bundle install`
- [ ] Run `rails db:create db:migrate db:seed`
- [ ] Generate VAPID keys: `rails generate vapid_keys`
- [ ] Add Google OAuth credentials to .env
- [ ] Test authentication flow
- [ ] Test timer functionality
- [ ] Test invoice generation

### Launch Commands
```bash
# Install dependencies
bundle install

# Setup database
rails db:create
rails db:migrate
rails db:seed

# Start server
./bin/dev

# Or with foreman
foreman start -f Procfile.dev
```

### Post-Launch Tasks
- [ ] Deploy to staging server
- [ ] Configure domain and SSL
- [ ] Set up error monitoring (Sentry/Rollbar)
- [ ] Configure backup strategy
- [ ] Create Android app wrapper

## 📱 Quick Android App Setup

Create a basic Android wrapper:

1. Create new Android project in Android Studio
2. Add Hotwire Native dependency
3. Point to your Rails app URL
4. Configure push notifications with FCM
5. Build and test on device

## 🔥 Critical Path for Today

1. **Hour 1-2**: Authentication + Models
2. **Hour 3-4**: Timer functionality 
3. **Hour 5**: Dashboard + Real-time updates
4. **Hour 6**: Basic invoicing
5. **Hour 7**: Testing + Bug fixes
6. **Hour 8**: Deploy to production

## 📝 Notes for Developer

- Focus on getting timer working first - this is the core feature
- Invoice PDF generation can be simplified initially (just HTML view)
- Skip email notifications for MVP
- Use Turbo Frames for modal forms
- Keep UI simple with Tailwind components
- Test on mobile browser before building native app

---

**Remember: Ship it today, perfect it tomorrow!** 🚀
