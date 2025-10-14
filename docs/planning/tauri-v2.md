# OnePunch Tauri Desktop App - Linux Implementation Plan

## Overview

This document outlines the architecture and implementation plan for building a native Linux desktop client for OnePunch time tracking using Tauri v2. The app will provide system tray integration, waybar menubar support, and full access to the OnePunch API.

**Target Platform**: Linux (primary focus on Wayland with X11 compatibility)
**Framework**: Tauri v2
**Backend**: Rust
**Frontend**: HTML/CSS/JavaScript (can use any framework later)

---

## Architecture

### Core Components

```
┌─────────────────────────────────────────────────┐
│              Frontend (Web Technologies)         │
│  ┌──────────────┐  ┌──────────────┐            │
│  │  Login View  │  │  Timer View  │            │
│  └──────────────┘  └──────────────┘            │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ Project List │  │  Time Entry  │            │
│  └──────────────┘  └──────────────┘            │
└─────────────────────────────────────────────────┘
                       │
                       │ IPC (Message Passing)
                       │
┌─────────────────────────────────────────────────┐
│              Rust Backend (Tauri Core)          │
│  ┌──────────────────────────────────────────┐  │
│  │  API Client (HTTP requests to OnePunch)  │  │
│  └──────────────────────────────────────────┘  │
│  ┌──────────────┐  ┌──────────────────────┐   │
│  │  State Mgmt  │  │  Timer Controller    │   │
│  │  (SQLite)    │  │  (Background Task)   │   │
│  └──────────────┘  └──────────────────────┘   │
│  ┌──────────────────────────────────────────┐  │
│  │  System Tray / Waybar Integration       │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
                       │
                       │ Native APIs
                       │
┌─────────────────────────────────────────────────┐
│              Linux System Layer                  │
│  ┌──────────────┐  ┌──────────────────────┐    │
│  │  WebKitGTK   │  │  D-Bus Notifications │    │
│  └──────────────┘  └──────────────────────┘    │
│  ┌──────────────┐  ┌──────────────────────┐    │
│  │ AppIndicator │  │  JSON stdout (waybar)│    │
│  └──────────────┘  └──────────────────────┘    │
└─────────────────────────────────────────────────┘
```

### Technology Stack

**Frontend:**
- Vanilla HTML/CSS/JavaScript initially (can migrate to React/Vue/Svelte later)
- Tailwind CSS for styling (matching OnePunch web UI)
- No bundler required (Tauri handles asset serving)

**Backend (Rust):**
- `tauri` v2 - Main framework
- `reqwest` - HTTP client for OnePunch API
- `serde` / `serde_json` - JSON serialization
- `tokio` - Async runtime
- `sqlx` or `rusqlite` - Local state persistence
- `chrono` - Time/date handling
- `tray-icon` - System tray support (Tauri v2 built-in)
- `libayatana-appindicator` - Linux system tray (runtime dependency)

**Platform Integration:**
- System tray via Tauri's tray API
- D-Bus notifications for desktop alerts
- Waybar custom script support via JSON stdout

---

## System Tray Integration

### Tauri v2 System Tray API

Tauri v2 provides built-in system tray support. On Linux, it automatically uses:
1. **libayatana-appindicator3** (preferred)
2. **libappindicator3** (fallback)

**Configuration** (`tauri.conf.json`):
```json
{
  "app": {
    "trayIcon": {
      "iconPath": "icons/tray-icon.png",
      "iconAsTemplate": false,
      "menuOnLeftClick": false,
      "title": "OnePunch"
    }
  }
}
```

**Rust Implementation:**
```rust
use tauri::{Manager, menu::{Menu, MenuItem}, tray::TrayIconBuilder};

fn setup_system_tray(app: &tauri::App) -> tauri::Result<()> {
    let quit = MenuItem::with_id(app, "quit", "Quit", true, None::<&str>)?;
    let show = MenuItem::with_id(app, "show", "Show OnePunch", true, None::<&str>)?;
    let start_timer = MenuItem::with_id(app, "start", "Start Timer", true, None::<&str>)?;
    let stop_timer = MenuItem::with_id(app, "stop", "Stop Timer", true, None::<&str>)?;

    let menu = Menu::with_items(app, &[
        &show,
        &start_timer,
        &stop_timer,
        &quit,
    ])?;

    let _tray = TrayIconBuilder::new()
        .menu(&menu)
        .icon(app.default_window_icon().unwrap().clone())
        .on_menu_event(|app, event| match event.id().as_ref() {
            "quit" => {
                app.exit(0);
            }
            "show" => {
                if let Some(window) = app.get_webview_window("main") {
                    let _ = window.show();
                    let _ = window.set_focus();
                }
            }
            "start" => {
                // Emit event to frontend or call backend function
                app.emit("start-timer", ()).unwrap();
            }
            "stop" => {
                app.emit("stop-timer", ()).unwrap();
            }
            _ => {}
        })
        .build(app)?;

    Ok(())
}
```

**Dynamic Tray Updates:**
Update tray icon based on timer state (running/stopped):
```rust
// Update tray icon when timer starts/stops
tray.set_icon(Some(icon_running))?;
tray.set_tooltip(Some("OnePunch - Timer Running: 01:23:45"))?;
```

---

## Waybar Integration

Waybar is a popular status bar for Wayland compositors (Sway, Hyprland, etc.). We can integrate OnePunch as a custom waybar module.

### Architecture

```
┌─────────────────────┐
│  OnePunch Tauri App │
│                     │
│  ┌───────────────┐ │
│  │ Waybar Script │ │  (Separate binary or script mode)
│  │   Generator   │ │
│  └───────┬───────┘ │
└──────────┼─────────┘
           │
           │ JSON stdout
           ▼
┌─────────────────────┐
│      Waybar         │
│  ┌───────────────┐  │
│  │ Custom Module │  │
│  └───────────────┘  │
└─────────────────────┘
```

### Waybar Custom Module Configuration

**User's waybar config** (`~/.config/waybar/config`):
```json
{
  "modules-right": ["custom/onepunch", "clock", "tray"],
  "custom/onepunch": {
    "exec": "/usr/local/bin/onepunch-waybar",
    "return-type": "json",
    "interval": 5,
    "format": "{icon} {text}",
    "format-icons": {
      "running": "⏱️",
      "stopped": "⏸️"
    },
    "on-click": "onepunch toggle-timer",
    "on-click-right": "onepunch show"
  }
}
```

**Waybar style** (`~/.config/waybar/style.css`):
```css
#custom-onepunch {
  padding: 0 10px;
  color: #ffffff;
}

#custom-onepunch.running {
  background-color: #10b981;
  color: #ffffff;
}

#custom-onepunch.stopped {
  background-color: #6b7280;
  color: #ffffff;
}
```

### Waybar Script Implementation

**Option 1: Separate Rust Binary** (`onepunch-waybar`)

Create a separate binary that queries the Tauri app's state:

```rust
use serde::Serialize;
use std::time::Duration;

#[derive(Serialize)]
struct WaybarOutput {
    text: String,
    tooltip: String,
    class: String,
    percentage: Option<u8>,
}

#[tokio::main]
async fn main() {
    loop {
        // Query timer status from OnePunch API or local state file
        let timer_status = get_timer_status().await;

        let output = match timer_status {
            TimerStatus::Running { duration, project } => WaybarOutput {
                text: format_duration(duration),
                tooltip: format!("Running: {}", project),
                class: "running".to_string(),
                percentage: None,
            },
            TimerStatus::Stopped => WaybarOutput {
                text: "Stopped".to_string(),
                tooltip: "Click to start timer".to_string(),
                class: "stopped".to_string(),
                percentage: None,
            },
        };

        println!("{}", serde_json::to_string(&output).unwrap());
        tokio::time::sleep(Duration::from_secs(5)).await;
    }
}
```

**Option 2: Shared State File**

The Tauri app writes timer state to a JSON file that the waybar script reads:

```rust
// In Tauri app - write state to file
async fn update_waybar_state(state: TimerState) {
    let state_path = dirs::runtime_dir()
        .unwrap_or_else(|| PathBuf::from("/tmp"))
        .join("onepunch-timer.json");

    let waybar_state = WaybarState {
        text: state.formatted_duration(),
        tooltip: state.tooltip(),
        class: if state.running { "running" } else { "stopped" },
    };

    tokio::fs::write(
        state_path,
        serde_json::to_string(&waybar_state).unwrap()
    ).await.ok();
}

// Waybar script - simple shell script or Rust binary
#!/bin/bash
# onepunch-waybar
while true; do
    cat /tmp/onepunch-timer.json
    sleep 5
done
```

**Option 3: D-Bus Integration**

More advanced: Expose timer state via D-Bus and query it from waybar script:

```rust
// Tauri app exposes D-Bus interface
// org.onepunch.Timer
// - GetStatus() -> (running: bool, duration: u64, project: string)

// Waybar script queries via D-Bus
dbus-send --print-reply --dest=org.onepunch.Timer \
  /org/onepunch/Timer org.onepunch.Timer.GetStatus
```

---

## OnePunch API Integration

### Authentication Flow

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    api_token: Option<String>,
    base_url: String,
    current_organization_id: Option<i64>,
}

#[derive(Debug, Clone)]
struct ApiClient {
    client: reqwest::Client,
    config: Config,
}

impl ApiClient {
    fn new(config: Config) -> Self {
        let client = reqwest::Client::new();
        Self { client, config }
    }

    async fn get_current_user(&self) -> Result<User, Error> {
        let response = self.client
            .get(&format!("{}/api/v1/users/me", self.config.base_url))
            .header("Authorization", format!("Bearer {}", self.config.api_token.as_ref().unwrap()))
            .send()
            .await?;

        let data: ApiResponse<User> = response.json().await?;
        Ok(data.data)
    }

    async fn start_timer(&self, project_id: i64, description: String) -> Result<TimeEntry, Error> {
        let body = serde_json::json!({
            "project_id": project_id,
            "description": description,
            "billable": true,
        });

        let response = self.client
            .post(&format!("{}/api/v1/timer/start", self.config.base_url))
            .header("Authorization", format!("Bearer {}", self.config.api_token.as_ref().unwrap()))
            .json(&body)
            .send()
            .await?;

        let data: ApiResponse<TimerResponse> = response.json().await?;
        Ok(data.data.time_entry)
    }

    async fn stop_timer(&self) -> Result<TimeEntry, Error> {
        let response = self.client
            .post(&format!("{}/api/v1/timer/stop", self.config.base_url))
            .header("Authorization", format!("Bearer {}", self.config.api_token.as_ref().unwrap()))
            .send()
            .await?;

        let data: ApiResponse<TimerResponse> = response.json().await?;
        Ok(data.data.time_entry)
    }

    async fn get_current_timer(&self) -> Result<Option<TimeEntry>, Error> {
        let response = self.client
            .get(&format!("{}/api/v1/timer/current", self.config.base_url))
            .header("Authorization", format!("Bearer {}", self.config.api_token.as_ref().unwrap()))
            .send()
            .await?;

        let data: ApiResponse<TimerResponse> = response.json().await?;
        if data.data.running {
            Ok(Some(data.data.time_entry))
        } else {
            Ok(None)
        }
    }

    async fn list_projects(&self) -> Result<Vec<Project>, Error> {
        let response = self.client
            .get(&format!("{}/api/v1/projects", self.config.base_url))
            .header("Authorization", format!("Bearer {}", self.config.api_token.as_ref().unwrap()))
            .send()
            .await?;

        let data: ApiResponse<Vec<Project>> = response.json().await?;
        Ok(data.data)
    }

    async fn list_time_entries(&self, filters: TimeEntryFilters) -> Result<Vec<TimeEntry>, Error> {
        let mut url = format!("{}/api/v1/time_entries", self.config.base_url);

        // Add query parameters
        let mut params = vec![];
        if let Some(project_id) = filters.project_id {
            params.push(format!("project_id={}", project_id));
        }
        if let Some(start_date) = filters.start_date {
            params.push(format!("start_date={}", start_date));
        }
        if let Some(end_date) = filters.end_date {
            params.push(format!("end_date={}", end_date));
        }

        if !params.is_empty() {
            url.push('?');
            url.push_str(&params.join("&"));
        }

        let response = self.client
            .get(&url)
            .header("Authorization", format!("Bearer {}", self.config.api_token.as_ref().unwrap()))
            .send()
            .await?;

        let data: ApiResponse<Vec<TimeEntry>> = response.json().await?;
        Ok(data.data)
    }
}
```

### Local State Persistence

Use SQLite to cache data for offline access and reduce API calls:

```rust
use sqlx::SqlitePool;

#[derive(Clone)]
struct AppState {
    db: SqlitePool,
    api_client: ApiClient,
}

impl AppState {
    async fn new(config: Config) -> Result<Self, Error> {
        let db = SqlitePool::connect("sqlite://onepunch.db").await?;

        // Run migrations
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS projects (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                client_name TEXT,
                hourly_rate REAL,
                status TEXT,
                color TEXT,
                synced_at INTEGER
            );

            CREATE TABLE IF NOT EXISTS time_entries (
                id INTEGER PRIMARY KEY,
                project_id INTEGER,
                description TEXT,
                started_at INTEGER NOT NULL,
                ended_at INTEGER,
                duration INTEGER,
                billable INTEGER,
                running INTEGER,
                synced_at INTEGER,
                FOREIGN KEY (project_id) REFERENCES projects(id)
            );
            "#
        )
        .execute(&db)
        .await?;

        let api_client = ApiClient::new(config);

        Ok(Self { db, api_client })
    }

    async fn sync_projects(&self) -> Result<(), Error> {
        let projects = self.api_client.list_projects().await?;

        for project in projects {
            sqlx::query(
                r#"
                INSERT OR REPLACE INTO projects
                (id, name, client_name, hourly_rate, status, color, synced_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                "#
            )
            .bind(project.id)
            .bind(&project.name)
            .bind(&project.client_name)
            .bind(project.hourly_rate)
            .bind(&project.status)
            .bind(&project.color)
            .bind(chrono::Utc::now().timestamp())
            .execute(&self.db)
            .await?;
        }

        Ok(())
    }

    async fn get_cached_projects(&self) -> Result<Vec<Project>, Error> {
        let projects = sqlx::query_as::<_, Project>(
            "SELECT * FROM projects WHERE status = 'active' ORDER BY name"
        )
        .fetch_all(&self.db)
        .await?;

        Ok(projects)
    }
}
```

---

## Background Timer Updates

The app needs to continuously update the running timer display and sync with the server.

### Timer Controller

```rust
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio::time::{interval, Duration};

#[derive(Debug, Clone)]
struct TimerState {
    running: bool,
    time_entry: Option<TimeEntry>,
    elapsed_seconds: u64,
}

struct TimerController {
    state: Arc<RwLock<TimerState>>,
    api_client: ApiClient,
    app_handle: tauri::AppHandle,
}

impl TimerController {
    fn new(api_client: ApiClient, app_handle: tauri::AppHandle) -> Self {
        let state = Arc::new(RwLock::new(TimerState {
            running: false,
            time_entry: None,
            elapsed_seconds: 0,
        }));

        Self {
            state,
            api_client,
            app_handle,
        }
    }

    async fn start(&self) {
        let state = self.state.clone();
        let api_client = self.api_client.clone();
        let app_handle = self.app_handle.clone();

        tokio::spawn(async move {
            let mut ticker = interval(Duration::from_secs(1));

            loop {
                ticker.tick().await;

                let mut state_lock = state.write().await;

                if state_lock.running {
                    state_lock.elapsed_seconds += 1;

                    // Update UI every second
                    app_handle.emit("timer-tick", TimerTickPayload {
                        elapsed: state_lock.elapsed_seconds,
                        formatted: format_duration(state_lock.elapsed_seconds),
                    }).ok();

                    // Sync with server every 30 seconds
                    if state_lock.elapsed_seconds % 30 == 0 {
                        if let Ok(current) = api_client.get_current_timer().await {
                            if let Some(entry) = current {
                                state_lock.time_entry = Some(entry);
                            } else {
                                // Timer stopped on server
                                state_lock.running = false;
                                state_lock.time_entry = None;
                                state_lock.elapsed_seconds = 0;
                            }
                        }
                    }
                }
            }
        });
    }

    async fn start_timer(&self, project_id: i64, description: String) -> Result<(), Error> {
        let entry = self.api_client.start_timer(project_id, description).await?;

        let mut state = self.state.write().await;
        state.running = true;
        state.time_entry = Some(entry);
        state.elapsed_seconds = 0;

        // Update tray icon
        self.app_handle.emit("timer-started", ()).ok();

        Ok(())
    }

    async fn stop_timer(&self) -> Result<(), Error> {
        let entry = self.api_client.stop_timer().await?;

        let mut state = self.state.write().await;
        state.running = false;
        state.time_entry = Some(entry);
        state.elapsed_seconds = 0;

        // Update tray icon
        self.app_handle.emit("timer-stopped", ()).ok();

        Ok(())
    }
}
```

---

## Desktop Notifications

Use D-Bus to send native Linux desktop notifications:

```rust
use notify_rust::Notification;

fn notify_timer_started(project_name: &str) {
    Notification::new()
        .summary("OnePunch Timer Started")
        .body(&format!("Timer started for: {}", project_name))
        .icon("onepunch-icon")
        .timeout(3000)
        .show()
        .ok();
}

fn notify_timer_stopped(duration: &str) {
    Notification::new()
        .summary("OnePunch Timer Stopped")
        .body(&format!("Duration: {}", duration))
        .icon("onepunch-icon")
        .timeout(3000)
        .show()
        .ok();
}
```

---

## UI Implementation

### Design System

**Color Palette:**

Light Mode (Monochrome Light Grays):
- Background: `#f9fafb` (gray-50)
- Surface: `#ffffff` (white)
- Borders: `#e5e7eb` (gray-200)
- Text Primary: `#111827` (gray-900)
- Text Secondary: `#6b7280` (gray-500)
- Accent: `#374151` (gray-700)
- Active Timer: `#10b981` (green-500)
- Hover: `#f3f4f6` (gray-100)

Dark Mode:
- Background: `#0f172a` (slate-900)
- Surface: `#1e293b` (slate-800)
- Borders: `#334155` (slate-700)
- Text Primary: `#f1f5f9` (slate-100)
- Text Secondary: `#94a3b8` (slate-400)
- Accent: `#cbd5e1` (slate-300)
- Active Timer: `#10b981` (green-500)
- Hover: `#334155` (slate-700)

**Typography:**
- Font Family: `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif`
- Font Sizes: 12px (small), 14px (body), 16px (heading), 20px (large heading)

**Spacing:**
- Base unit: 8px (0.5rem)
- Small: 4px, Medium: 8px, Large: 16px, XL: 24px

**Border Radius:**
- Small: 4px, Medium: 6px, Large: 8px

### Frontend Architecture

The frontend will be a single-page application with these main views:

1. **Login View** - API token authentication
2. **Dashboard View** - Timer controller + recent entries
3. **Projects View** - List of projects with stats
4. **Time Entries View** - Detailed time entry list
5. **Settings View** - Configuration & theme toggle

### Primary UI Layout

**Timer Controller Bar** (Always visible at top):
```
┌──────────────────────────────────────────────────────────────┐
│  [Project Dropdown ▼]  [Description Input]  [▶ Start / ⏸ Stop]│
│  Timer: 01:23:45                                              │
└──────────────────────────────────────────────────────────────┘
```

The timer controller is the most prominent feature, positioned at the top of every view for quick access.

### Complete UI Examples

#### Login View HTML

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>OnePunch</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body class="theme-light">
    <div id="app">
        <!-- Login View -->
        <div id="login-view" class="view">
            <div class="login-container">
                <h1>OnePunch Time Tracking</h1>
                <p class="subtitle">Desktop Client</p>
                <form id="login-form">
                    <div class="form-group">
                        <label>API Token</label>
                        <input type="password" id="api-token" placeholder="Enter your API token">
                        <p class="help-text">
                            Get your token from Settings → Account in the web app
                        </p>
                    </div>
                    <button type="submit" class="btn-primary">Login</button>
                </form>
            </div>
        </div>

        <!-- Dashboard View (hidden initially) -->
        <div id="dashboard-view" class="view hidden">
            <!-- Timer Controller Bar -->
            <div class="timer-bar">
                <div class="timer-controls">
                    <select id="project-select" class="project-dropdown">
                        <option value="">Select Project...</option>
                        <!-- Populated dynamically -->
                    </select>
                    <input
                        type="text"
                        id="description-input"
                        class="description-input"
                        placeholder="What are you working on?"
                    >
                    <button id="timer-toggle-btn" class="btn-timer">
                        <span class="icon">▶</span>
                        <span class="label">Start</span>
                    </button>
                </div>
                <div class="timer-display">
                    <span class="timer-label">Timer:</span>
                    <span id="timer-value" class="timer-value">00:00:00</span>
                </div>
            </div>

            <!-- Navigation -->
            <nav class="nav-tabs">
                <button class="nav-tab active" data-view="recent">Recent</button>
                <button class="nav-tab" data-view="projects">Projects</button>
                <button class="nav-tab" data-view="entries">Time Entries</button>
                <button class="nav-tab" data-view="settings">Settings</button>
            </nav>

            <!-- Content Area -->
            <div class="content">
                <div id="recent-view" class="content-view active">
                    <h2>Recent Entries</h2>
                    <div id="recent-entries-list" class="entries-list">
                        <!-- Populated dynamically -->
                    </div>
                </div>

                <div id="projects-view" class="content-view hidden">
                    <h2>Projects</h2>
                    <div id="projects-list" class="projects-list">
                        <!-- Populated dynamically -->
                    </div>
                </div>

                <div id="entries-view" class="content-view hidden">
                    <h2>Time Entries</h2>
                    <div id="entries-list" class="entries-list">
                        <!-- Populated dynamically -->
                    </div>
                </div>

                <div id="settings-view" class="content-view hidden">
                    <h2>Settings</h2>
                    <div class="settings-section">
                        <label class="setting-item">
                            <span>Theme</span>
                            <select id="theme-select">
                                <option value="light">Light</option>
                                <option value="dark">Dark</option>
                                <option value="system">System</option>
                            </select>
                        </label>
                        <label class="setting-item">
                            <span>Notifications</span>
                            <input type="checkbox" id="notifications-toggle" checked>
                        </label>
                        <label class="setting-item">
                            <span>Auto-start</span>
                            <input type="checkbox" id="autostart-toggle">
                        </label>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script type="module" src="main.js"></script>
</body>
</html>
```

#### CSS Stylesheet

```css
/* styles.css */

/* CSS Variables for Theming */
.theme-light {
    --bg-primary: #f9fafb;
    --bg-secondary: #ffffff;
    --bg-hover: #f3f4f6;
    --border-color: #e5e7eb;
    --text-primary: #111827;
    --text-secondary: #6b7280;
    --accent: #374151;
    --timer-active: #10b981;
}

.theme-dark {
    --bg-primary: #0f172a;
    --bg-secondary: #1e293b;
    --bg-hover: #334155;
    --border-color: #334155;
    --text-primary: #f1f5f9;
    --text-secondary: #94a3b8;
    --accent: #cbd5e1;
    --timer-active: #10b981;
}

/* Reset & Base Styles */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    font-size: 14px;
    color: var(--text-primary);
    background-color: var(--bg-primary);
    line-height: 1.5;
}

/* Login View */
.login-container {
    max-width: 400px;
    margin: 100px auto;
    padding: 32px;
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: 8px;
}

.login-container h1 {
    font-size: 24px;
    margin-bottom: 8px;
    color: var(--text-primary);
}

.login-container .subtitle {
    font-size: 14px;
    color: var(--text-secondary);
    margin-bottom: 24px;
}

/* Form Elements */
.form-group {
    margin-bottom: 16px;
}

.form-group label {
    display: block;
    font-size: 14px;
    font-weight: 500;
    margin-bottom: 6px;
    color: var(--text-primary);
}

.form-group input[type="text"],
.form-group input[type="password"] {
    width: 100%;
    padding: 8px 12px;
    font-size: 14px;
    border: 1px solid var(--border-color);
    border-radius: 6px;
    background: var(--bg-secondary);
    color: var(--text-primary);
}

.form-group input:focus {
    outline: none;
    border-color: var(--accent);
}

.help-text {
    margin-top: 6px;
    font-size: 12px;
    color: var(--text-secondary);
}

/* Buttons */
.btn-primary {
    width: 100%;
    padding: 10px 16px;
    font-size: 14px;
    font-weight: 500;
    color: #ffffff;
    background: var(--accent);
    border: none;
    border-radius: 6px;
    cursor: pointer;
}

.btn-primary:hover {
    opacity: 0.9;
}

/* Timer Bar */
.timer-bar {
    background: var(--bg-secondary);
    border-bottom: 1px solid var(--border-color);
    padding: 16px;
}

.timer-controls {
    display: flex;
    gap: 8px;
    margin-bottom: 12px;
}

.project-dropdown {
    flex: 0 0 200px;
    padding: 8px 12px;
    font-size: 14px;
    border: 1px solid var(--border-color);
    border-radius: 6px;
    background: var(--bg-secondary);
    color: var(--text-primary);
    cursor: pointer;
}

.description-input {
    flex: 1;
    padding: 8px 12px;
    font-size: 14px;
    border: 1px solid var(--border-color);
    border-radius: 6px;
    background: var(--bg-secondary);
    color: var(--text-primary);
}

.btn-timer {
    flex: 0 0 100px;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    padding: 8px 16px;
    font-size: 14px;
    font-weight: 500;
    color: #ffffff;
    background: var(--accent);
    border: none;
    border-radius: 6px;
    cursor: pointer;
}

.btn-timer.running {
    background: var(--timer-active);
}

.timer-display {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 16px;
}

.timer-label {
    color: var(--text-secondary);
    font-weight: 500;
}

.timer-value {
    color: var(--text-primary);
    font-weight: 600;
    font-variant-numeric: tabular-nums;
}

.timer-value.running {
    color: var(--timer-active);
}

/* Navigation Tabs */
.nav-tabs {
    display: flex;
    gap: 4px;
    padding: 0 16px;
    background: var(--bg-secondary);
    border-bottom: 1px solid var(--border-color);
}

.nav-tab {
    padding: 12px 16px;
    font-size: 14px;
    font-weight: 500;
    color: var(--text-secondary);
    background: transparent;
    border: none;
    border-bottom: 2px solid transparent;
    cursor: pointer;
}

.nav-tab:hover {
    color: var(--text-primary);
}

.nav-tab.active {
    color: var(--text-primary);
    border-bottom-color: var(--accent);
}

/* Content Area */
.content {
    padding: 16px;
}

.content-view {
    display: none;
}

.content-view.active {
    display: block;
}

.content h2 {
    font-size: 20px;
    margin-bottom: 16px;
    color: var(--text-primary);
}

/* Entries List */
.entries-list {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.entry-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px;
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: 6px;
}

.entry-item:hover {
    background: var(--bg-hover);
}

.entry-info {
    flex: 1;
}

.entry-project {
    font-size: 14px;
    font-weight: 500;
    color: var(--text-primary);
}

.entry-description {
    font-size: 12px;
    color: var(--text-secondary);
    margin-top: 2px;
}

.entry-duration {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-primary);
    font-variant-numeric: tabular-nums;
}

/* Projects List */
.projects-list {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
    gap: 12px;
}

.project-card {
    padding: 16px;
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: 6px;
    cursor: pointer;
}

.project-card:hover {
    background: var(--bg-hover);
}

.project-name {
    font-size: 16px;
    font-weight: 500;
    margin-bottom: 4px;
    color: var(--text-primary);
}

.project-client {
    font-size: 12px;
    color: var(--text-secondary);
}

/* Settings */
.settings-section {
    max-width: 500px;
}

.setting-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 16px 0;
    border-bottom: 1px solid var(--border-color);
}

.setting-item span {
    font-size: 14px;
    font-weight: 500;
    color: var(--text-primary);
}

.setting-item select {
    padding: 6px 12px;
    font-size: 14px;
    border: 1px solid var(--border-color);
    border-radius: 6px;
    background: var(--bg-secondary);
    color: var(--text-primary);
}

.setting-item input[type="checkbox"] {
    width: 20px;
    height: 20px;
    cursor: pointer;
}

/* Utility Classes */
.hidden {
    display: none !important;
}

.view {
    min-height: 100vh;
}
```

#### JavaScript Implementation

```javascript
// main.js
const { invoke } = window.__TAURI__.core;
const { listen } = window.__TAURI__.event;

// State
let currentUser = null;
let projects = [];
let isTimerRunning = false;

// Initialize app
document.addEventListener('DOMContentLoaded', () => {
    initializeTheme();
    setupEventListeners();
    checkAuth();
});

// Theme Management
function initializeTheme() {
    const savedTheme = localStorage.getItem('theme') || 'light';
    applyTheme(savedTheme);

    const themeSelect = document.getElementById('theme-select');
    if (themeSelect) {
        themeSelect.value = savedTheme;
        themeSelect.addEventListener('change', (e) => {
            const theme = e.target.value;
            applyTheme(theme);
            localStorage.setItem('theme', theme);
        });
    }
}

function applyTheme(theme) {
    const effectiveTheme = theme === 'system'
        ? (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
        : theme;

    document.body.className = `theme-${effectiveTheme}`;
}

// Authentication
async function checkAuth() {
    try {
        const user = await invoke('get_current_user');
        currentUser = user;
        showDashboard();
    } catch (error) {
        showLogin();
    }
}

function showLogin() {
    document.getElementById('login-view').classList.remove('hidden');
    document.getElementById('dashboard-view').classList.add('hidden');
}

function showDashboard() {
    document.getElementById('login-view').classList.add('hidden');
    document.getElementById('dashboard-view').classList.remove('hidden');
    loadProjects();
    loadRecentEntries();
    checkCurrentTimer();
}

// Login Handler
document.getElementById('login-form')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const token = document.getElementById('api-token').value;

    try {
        const user = await invoke('login', { apiToken: token });
        currentUser = user;
        showDashboard();
    } catch (error) {
        alert('Login failed: ' + error);
    }
});

// Timer Controls
async function checkCurrentTimer() {
    try {
        const timer = await invoke('get_current_timer');
        if (timer) {
            updateTimerUI(timer);
        }
    } catch (error) {
        console.error('Failed to check timer:', error);
    }
}

document.getElementById('timer-toggle-btn')?.addEventListener('click', async () => {
    if (isTimerRunning) {
        await stopTimer();
    } else {
        await startTimer();
    }
});

async function startTimer() {
    const projectSelect = document.getElementById('project-select');
    const descriptionInput = document.getElementById('description-input');

    const projectId = parseInt(projectSelect.value);
    const description = descriptionInput.value;

    if (!projectId) {
        alert('Please select a project');
        return;
    }

    try {
        await invoke('start_timer', { projectId, description });
        isTimerRunning = true;
        updateTimerButton(true);
    } catch (error) {
        alert('Failed to start timer: ' + error);
    }
}

async function stopTimer() {
    try {
        await invoke('stop_timer');
        isTimerRunning = false;
        updateTimerButton(false);
        loadRecentEntries(); // Refresh entries list
    } catch (error) {
        alert('Failed to stop timer: ' + error);
    }
}

function updateTimerButton(running) {
    const btn = document.getElementById('timer-toggle-btn');
    const icon = btn.querySelector('.icon');
    const label = btn.querySelector('.label');

    if (running) {
        btn.classList.add('running');
        icon.textContent = '⏸';
        label.textContent = 'Stop';
    } else {
        btn.classList.remove('running');
        icon.textContent = '▶';
        label.textContent = 'Start';
    }
}

function updateTimerUI(timer) {
    const timerValue = document.getElementById('timer-value');
    timerValue.textContent = timer.formatted;

    if (timer.running) {
        timerValue.classList.add('running');
    } else {
        timerValue.classList.remove('running');
    }
}

// Listen for timer updates from Rust backend
listen('timer-tick', (event) => {
    updateTimerUI(event.payload);
});

// Projects
async function loadProjects() {
    try {
        projects = await invoke('get_projects');
        populateProjectDropdown();
        renderProjectsList();
    } catch (error) {
        console.error('Failed to load projects:', error);
    }
}

function populateProjectDropdown() {
    const select = document.getElementById('project-select');
    select.innerHTML = '<option value="">Select Project...</option>';

    projects.forEach(project => {
        const option = document.createElement('option');
        option.value = project.id;
        option.textContent = project.name;
        select.appendChild(option);
    });
}

function renderProjectsList() {
    const container = document.getElementById('projects-list');
    if (!container) return;

    container.innerHTML = '';

    projects.forEach(project => {
        const card = document.createElement('div');
        card.className = 'project-card';
        card.innerHTML = `
            <div class="project-name">${project.name}</div>
            <div class="project-client">${project.client_name || 'No client'}</div>
        `;
        card.addEventListener('click', () => selectProject(project.id));
        container.appendChild(card);
    });
}

function selectProject(projectId) {
    document.getElementById('project-select').value = projectId;
    switchTab('recent'); // Switch to recent entries view
}

// Time Entries
async function loadRecentEntries() {
    try {
        const entries = await invoke('list_time_entries', {
            filters: {
                start_date: new Date().toISOString().split('T')[0],
                end_date: new Date().toISOString().split('T')[0]
            }
        });
        renderEntriesList(entries, 'recent-entries-list');
    } catch (error) {
        console.error('Failed to load entries:', error);
    }
}

function renderEntriesList(entries, containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;

    container.innerHTML = '';

    if (entries.length === 0) {
        container.innerHTML = '<p style="color: var(--text-secondary);">No entries yet</p>';
        return;
    }

    entries.forEach(entry => {
        const item = document.createElement('div');
        item.className = 'entry-item';
        item.innerHTML = `
            <div class="entry-info">
                <div class="entry-project">${entry.project_name}</div>
                <div class="entry-description">${entry.description || 'No description'}</div>
            </div>
            <div class="entry-duration">${entry.formatted_duration}</div>
        `;
        container.appendChild(item);
    });
}

// Navigation
function setupEventListeners() {
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.addEventListener('click', (e) => {
            const view = e.target.dataset.view;
            switchTab(view);
        });
    });
}

function switchTab(view) {
    // Update tab buttons
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.classList.toggle('active', tab.dataset.view === view);
    });

    // Update content views
    document.querySelectorAll('.content-view').forEach(contentView => {
        contentView.classList.toggle('active', contentView.id === `${view}-view`);
    });
}
```

### Tauri Commands (Backend)

```rust
use tauri::State;

#[tauri::command]
async fn login(api_token: String, state: State<'_, AppState>) -> Result<User, String> {
    let mut config = state.api_client.config.clone();
    config.api_token = Some(api_token.clone());

    let api_client = ApiClient::new(config.clone());
    let user = api_client.get_current_user()
        .await
        .map_err(|e| format!("Login failed: {}", e))?;

    // Save token to config
    save_config(&config).await.map_err(|e| e.to_string())?;

    // Sync initial data
    state.sync_projects().await.map_err(|e| e.to_string())?;

    Ok(user)
}

#[tauri::command]
async fn start_timer(
    project_id: i64,
    description: String,
    state: State<'_, AppState>,
    timer: State<'_, TimerController>,
) -> Result<(), String> {
    timer.start_timer(project_id, description)
        .await
        .map_err(|e| e.to_string())?;

    notify_timer_started(&format!("Project {}", project_id));

    Ok(())
}

#[tauri::command]
async fn stop_timer(
    timer: State<'_, TimerController>,
) -> Result<TimeEntry, String> {
    let entry = timer.stop_timer()
        .await
        .map_err(|e| e.to_string())?;

    notify_timer_stopped(&entry.formatted_duration);

    Ok(entry)
}

#[tauri::command]
async fn get_projects(state: State<'_, AppState>) -> Result<Vec<Project>, String> {
    // Try to get from cache first
    let cached = state.get_cached_projects().await.ok();

    // Fetch fresh data in background
    tokio::spawn(async move {
        state.sync_projects().await.ok();
    });

    // Return cached data immediately
    cached.ok_or_else(|| "No projects found".to_string())
}

#[tauri::command]
async fn list_time_entries(
    filters: TimeEntryFilters,
    state: State<'_, AppState>,
) -> Result<Vec<TimeEntry>, String> {
    state.api_client.list_time_entries(filters)
        .await
        .map_err(|e| e.to_string())
}
```

---

## Project Structure

```
onepunch-desktop/
├── src-tauri/
│   ├── src/
│   │   ├── main.rs              # App entry point
│   │   ├── api/
│   │   │   ├── mod.rs
│   │   │   ├── client.rs        # API client
│   │   │   └── models.rs        # Data models
│   │   ├── state/
│   │   │   ├── mod.rs
│   │   │   └── database.rs      # SQLite persistence
│   │   ├── timer/
│   │   │   ├── mod.rs
│   │   │   └── controller.rs    # Timer controller
│   │   ├── tray.rs              # System tray setup
│   │   ├── waybar.rs            # Waybar integration
│   │   ├── commands.rs          # Tauri commands
│   │   └── config.rs            # Configuration management
│   ├── Cargo.toml
│   ├── tauri.conf.json
│   └── icons/
│       ├── icon.png
│       ├── tray-icon.png
│       └── tray-icon-active.png
├── src/
│   ├── index.html
│   ├── styles.css
│   ├── main.js
│   └── views/
│       ├── login.js
│       ├── dashboard.js
│       ├── projects.js
│       └── time_entries.js
├── onepunch-waybar/             # Separate waybar script binary
│   ├── src/
│   │   └── main.rs
│   └── Cargo.toml
└── README.md
```

---

## Implementation Phases

### Phase 1: Foundation (MVP)
**Goal**: Basic working app with timer functionality

**Tasks:**
1. Set up Tauri v2 project structure
2. Implement API client for OnePunch API
3. Create login flow with API token authentication
4. Build basic timer start/stop functionality
5. Add system tray with start/stop menu
6. Implement simple dashboard view showing current timer
7. Local config storage for API token

**Deliverable**: Functional Linux app that can start/stop timers

### Phase 2: Core Features
**Goal**: Full-featured desktop client

**Tasks:**
1. Implement project listing and selection
2. Add time entry browsing (today, this week, custom range)
3. Create manual time entry creation/editing
4. Add organization switching support
5. Implement background sync with server
6. Add SQLite caching for offline support
7. Desktop notifications for timer events

**Deliverable**: Feature-complete desktop app matching web functionality

### Phase 3: Linux Integration
**Goal**: Deep Linux desktop integration

**Tasks:**
1. Build waybar custom script support
2. Implement D-Bus interface for external control
3. Add keyboard shortcuts (global hotkeys)
4. Create .desktop file for app launcher
5. Package as AppImage, Flatpak, or .deb
6. Add auto-start on login option
7. Test on various Linux distributions (Ubuntu, Fedora, Arch)

**Deliverable**: Production-ready Linux app with native integration

### Phase 4: Polish & Distribution
**Goal**: Refined UX and easy installation

**Tasks:**
1. Improve UI/UX with better animations and feedback
2. Add comprehensive error handling and retry logic
3. Implement auto-update mechanism
4. Create installation documentation
5. Set up GitHub releases with binary artifacts
6. Add telemetry/crash reporting (optional)
7. User documentation and screenshots

**Deliverable**: Polished app ready for public release

---

## Linux Distribution & Packaging

### Runtime Dependencies

**Required:**
- `webkit2gtk-4.1` - Webview rendering
- `libayatana-appindicator3-1` - System tray (or libappindicator3-1)
- `libnotify` - Desktop notifications

### Package Formats

**1. AppImage** (Universal, no installation required)
```bash
# Build AppImage with cargo-appimage
cargo install cargo-appimage
cargo appimage
```

**2. Debian/Ubuntu (.deb)**
```bash
# Use cargo-deb
cargo install cargo-deb
cargo deb
```

**3. Flatpak** (Sandboxed, works on all distros)
Create `org.onepunch.OnePunch.yml` manifest and build with flatpak-builder

**4. AUR Package** (Arch Linux)
Create PKGBUILD for Arch User Repository

### Desktop Entry

`onepunch.desktop`:
```ini
[Desktop Entry]
Name=OnePunch Time Tracking
Comment=Desktop client for OnePunch time tracking
Exec=/usr/bin/onepunch
Icon=onepunch
Type=Application
Categories=Office;Productivity;
StartupNotify=true
X-GNOME-Autostart-enabled=true
```

---

## Security Considerations

1. **API Token Storage**: Store in encrypted keyring using `secret-service` crate
2. **HTTPS Only**: Enforce HTTPS for API communication
3. **Input Validation**: Validate all user inputs before sending to API
4. **No Plaintext Secrets**: Never log or store API tokens in plaintext
5. **CSP Headers**: Configure Content Security Policy in Tauri config
6. **Sandboxing**: Consider Flatpak for additional sandboxing

---

## Testing Strategy

1. **Unit Tests**: Test API client, timer logic, state management
2. **Integration Tests**: Test Tauri command handlers
3. **Manual Testing**: Test on multiple Linux distributions
   - Ubuntu 22.04+ (GNOME + Wayland)
   - Fedora 39+ (GNOME + Wayland)
   - Arch Linux (KDE Plasma + Wayland)
   - Pop!_OS (COSMIC + Wayland)
   - Test with Sway/Hyprland/river for waybar integration

---

## Configuration

`~/.config/onepunch/config.json`:
```json
{
  "api_token": null,
  "base_url": "https://onepunch.work",
  "current_organization_id": null,
  "theme": "system",
  "notifications_enabled": true,
  "auto_start": false,
  "waybar_enabled": false,
  "sync_interval_seconds": 300
}
```

---

## Future Enhancements

1. **Pomodoro Timer**: Built-in pomodoro technique support
2. **Offline Mode**: Queue actions when offline, sync when online
3. **Multiple Timer Windows**: Support for multiple simultaneous timers
4. **Reports**: Local reporting with charts and graphs
5. **Voice Commands**: Integration with speech recognition
6. **Custom Themes**: Theming support beyond light/dark
7. **Plugin System**: Allow community extensions
8. **Mobile Sync**: Sync with mobile app (future)

---

## Resources

### Documentation
- [Tauri v2 Documentation](https://v2.tauri.app/)
- [Tauri System Tray Guide](https://v2.tauri.app/learn/system-tray/)
- [Waybar Custom Module](https://man.archlinux.org/man/waybar-custom.5.en)
- [OnePunch API Documentation](docs/reference/api.md)

### Libraries
- [tauri](https://crates.io/crates/tauri) - Framework
- [reqwest](https://crates.io/crates/reqwest) - HTTP client
- [serde](https://crates.io/crates/serde) - Serialization
- [sqlx](https://crates.io/crates/sqlx) - Database
- [notify-rust](https://crates.io/crates/notify-rust) - Notifications
- [chrono](https://crates.io/crates/chrono) - Date/time

### Community
- [Tauri Discord](https://discord.com/invite/tauri)
- [r/tauri](https://reddit.com/r/tauri)
- [Tauri GitHub](https://github.com/tauri-apps/tauri)

---

## Next Steps

1. **Prototype**: Build minimal prototype with login + timer
2. **Design Mockups**: Create UI mockups for all views
3. **Architecture Review**: Review with team before implementation
4. **Repository Setup**: Create `onepunch-desktop` repository
5. **CI/CD Pipeline**: Set up automated builds and releases

---

## Questions to Resolve

1. Should we support Windows/macOS in addition to Linux?
2. What's the minimum Linux kernel/distribution version to support?
3. Should waybar integration be built-in or a separate package?
4. Do we need a separate daemon process or keep everything in one app?
5. Should we support running headless (CLI-only mode)?
6. What telemetry/analytics do we want (if any)?
7. Should we implement OAuth in addition to API token auth?

---

**Document Version**: 1.0
**Last Updated**: 2025-10-15
**Author**: OnePunch Development Team
