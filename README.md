# OnePunch - Time Tracking & Invoicing

A modern, **no-build** Rails application for time tracking and invoicing with native mobile support via Hotwire Native.

## 🚀 Features

- **⏱️ One-Click Time Tracking** - Start/stop timers with a single "punch"
- **📊 Real-time Updates** - Live dashboard with Turbo Streams (no page refresh)
- **💰 Professional Invoicing** - Generate PDF invoices from tracked time
- **📱 Mobile Ready** - Progressive Web App + Android app via Hotwire Native
- **🔔 Push Notifications** - Web push & native mobile notifications
- **📁 File Management** - Upload receipts and documents with ActiveStorage
- **🎨 Modern UI** - Tailwind CSS with dark mode support
- **🔄 Offline Support** - Service worker for offline functionality
- **📈 Analytics** - Time reports, revenue tracking, and insights

## 🛠️ Tech Stack

- **Framework**: Rails 8.1 edge (with Job Continuations, Native Push)
- **Frontend**: Hotwire (Turbo 8 + Stimulus 3) - **NO JavaScript build required**
- **Styling**: Tailwind CSS (with standalone CLI)
- **Database**: PostgreSQL 15+
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **WebSockets**: Solid Cable
- **Deployment**: Kamal 2 + Thruster
- **Mobile**: Hotwire Native for Android

## 📋 Prerequisites

- Ruby 3.4.5 (managed via mise)
- PostgreSQL 15+
- Redis 7+
- Tailwind CSS standalone CLI

## 🚀 Quick Start

### 1. Clone and Setup

```bash
cd /work/onepunch

# Install mise if not already installed
# curl https://mise.jdx.dev/mise-latest-linux-x64 > ~/.local/bin/mise
# chmod +x ~/.local/bin/mise

# Install dependencies
mise install
bundle install
```

### 2. Database Setup

```bash
# Create and migrate database
rails db:create
rails db:migrate
rails db:seed
```

### 3. Environment Configuration

```bash
# Copy environment file
cp .env.development .env

# Generate VAPID keys for push notifications
rails generate vapid_keys
# Add the keys to .env file
```

### 4. Start the Application

```bash
# Start all services (Rails + Tailwind CSS)
./bin/dev

# Or start individually:
# Rails server on port 2030
rails server -p 2030

# Tailwind CSS watcher (in another terminal)
rails tailwindcss:watch
```

Visit http://localhost:2030

## 🏗️ Architecture

### No-Build Philosophy

This application follows Rails' **no-build** approach:

- **JavaScript**: Import maps (no bundler, no node_modules for JS)
- **CSS**: Tailwind standalone CLI (simple CSS compilation)
- **Assets**: Sprockets for images and fonts
- **Libraries**: Loaded via CDN with importmap-rails

### Core Models

```
User
├── has_many :projects
├── has_many :time_entries
├── has_many :invoices
└── has_many :clients

Project
├── belongs_to :client
├── has_many :time_entries
└── has_many :invoices

TimeEntry
├── belongs_to :user
├── belongs_to :project
└── attributes: started_at, ended_at, duration, description

Invoice
├── belongs_to :client
├── belongs_to :project
├── has_many :line_items
└── has_one_attached :pdf

Client
├── has_many :projects
└── has_many :invoices
```

### Key Features

#### Real-time Time Tracking
- Turbo Streams for live updates
- ActionCable for presence tracking
- Server-side timer state

#### Push Notifications
- Web Push API for browser notifications
- Service Worker for offline support
- Native push for Android (via FCM)

#### Progressive Web App
- Installable on mobile and desktop
- Offline-first with service worker
- App-like navigation with Turbo

## 📱 Mobile App (Android)

The Android app uses Hotwire Native to wrap the web app with native navigation and features.

### Setup Android App

1. Install Android Studio
2. Clone the companion Android repository (coming soon)
3. Update `gradle.properties` with your server URL
4. Build and run on emulator or device

### Native Features
- Push notifications via FCM
- Camera access for receipts
- Native navigation
- Offline support

## 📋 Development Progress

### TODO Files
Development is tracked through sequential TODO files in `docs/`:

- [x] `docs/todo_01.md` - MVP Launch Plan (Authentication, Core Models, Timer, Invoicing)
- [ ] `docs/todo_02.md` - Enhanced Features (coming soon)
- [ ] `docs/todo_03.md` - Mobile App Development (coming soon)

Check off items as completed and create new TODO files for next phases.

## 🔧 Development

### Running Tests

```bash
rails test
rails test:system
```

### Code Quality

```bash
# Ruby linting
rubocop

# Security scan
brakeman
```

### Useful Commands

```bash
# Generate models
rails g model Client name:string email:string
rails g model Project name:string client:references hourly_rate:decimal
rails g model TimeEntry user:references project:references started_at:datetime ended_at:datetime

# Generate controllers
rails g controller TimeTracking
rails g controller Invoices

# Generate Stimulus controllers
rails g stimulus timer
rails g stimulus notification

# Database commands
rails db:migrate
rails db:rollback
rails db:seed
```

## 🚀 Deployment

Using Kamal 2 for zero-downtime deployments:

```bash
# First time setup
kamal setup

# Deploy
kamal deploy

# Rollback
kamal rollback
```

## 🔍 API Endpoints (for Mobile App)

```
POST   /api/auth/login
POST   /api/auth/logout
GET    /api/time_entries
POST   /api/time_entries/start
POST   /api/time_entries/:id/stop
GET    /api/projects
GET    /api/dashboard
```

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Kill process on port 2030
lsof -ti:2030 | xargs kill -9
```

### Tailwind Not Compiling
```bash
# Rebuild Tailwind
rails tailwindcss:build

# Watch for changes
rails tailwindcss:watch
```

### Database Connection Issues
```bash
# Check PostgreSQL status
systemctl status postgresql

# Reset database
rails db:drop db:create db:migrate
```

## 📚 Resources

- [Rails 8.1 Release Notes](https://rubyonrails.org/2025/9/4/rails-8-1-beta-1)
- [Hotwire Native Documentation](https://native.hotwired.dev/)
- [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)
- [Stimulus Reference](https://stimulus.hotwired.dev/reference/controllers)
- [Tailwind CSS](https://tailwindcss.com/docs)

## 📝 License

MIT License - see LICENSE file for details

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

Built with ❤️ using Rails 8.1 and Hotwire
