# OnePunch Time Tracking API v1

## Overview

The OnePunch API allows external time tracking clients to integrate with the OnePunch time tracking system. The API uses token-based authentication and follows RESTful conventions.

**Base URL**: `https://onepunch.work/api/v1` (or `http://localhost:2030/api/v1` for development)

## Authentication

All API requests require authentication using a Bearer token in the Authorization header.

### Getting Your API Token

1. Log into OnePunch web application
2. Navigate to Settings > Account
3. Find your API token or generate a new one

### Using the API Token

Include the token in the Authorization header of each request:

```bash
Authorization: Bearer YOUR_API_TOKEN
```

### Example Request

```bash
curl -H "Authorization: Bearer YOUR_API_TOKEN" \
     https://onepunch.work/api/v1/users/me
```

## Organization Context

OnePunch supports multiple organizations per user. By default, API requests use the user's current organization. To specify a different organization, include the `X-Organization-ID` header:

```bash
X-Organization-ID: 123
```

## Response Format

All successful responses return JSON with this structure:

```json
{
  "data": { ... },
  "meta": { ... }  // Optional, used for pagination
}
```

Error responses:

```json
{
  "error": "Error message",
  "details": ["Detailed error 1", "Detailed error 2"]  // Optional
}
```

## Endpoints

### User Information

#### Get Current User
```
GET /api/v1/users/me
```

Returns information about the authenticated user and their organizations.

**Response:**
```json
{
  "data": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "full_name": "John Doe",
    "current_organization": {
      "id": 1,
      "name": "Acme Corp",
      "display_name": "Acme Corp",
      "personal": false,
      "role": "owner"
    },
    "organizations": [...]
  }
}
```

#### Regenerate API Token
```
POST /api/v1/users/regenerate_token
```

Generates a new API token. **Warning**: This will invalidate your current token.

**Response:**
```json
{
  "data": {
    "api_token": "new_token_here",
    "message": "API token has been regenerated. Please update your applications."
  }
}
```

---

### Timer Control

#### Get Current Timer Status
```
GET /api/v1/timer/current
```

Returns the currently running timer, if any.

**Response:**
```json
{
  "data": {
    "running": true,
    "time_entry": {
      "id": 123,
      "project_id": 5,
      "project_name": "Client Project",
      "description": "Working on feature X",
      "started_at": "2025-10-15T10:30:00Z",
      "ended_at": null,
      "duration": null,
      "formatted_duration": "Running...",
      "billable": true,
      "running": true,
      "created_at": "2025-10-15T10:30:00Z",
      "updated_at": "2025-10-15T10:30:00Z"
    }
  }
}
```

#### Start Timer
```
POST /api/v1/timer/start
```

Starts a new timer. Automatically stops any currently running timer.

**Parameters:**
- `project_id` (required): ID of the project
- `description` (optional): Description of the work
- `billable` (optional, default: true): Whether the time is billable

**Request:**
```json
{
  "project_id": 5,
  "description": "Working on feature X",
  "billable": true
}
```

**Response:** (Same as Get Current Timer Status)

#### Stop Timer
```
POST /api/v1/timer/stop
```

Stops the currently running timer.

**Response:** Returns the stopped time entry with `ended_at` and `duration` populated.

---

### Time Entries

#### List Time Entries
```
GET /api/v1/time_entries
```

Returns a list of time entries for the current organization.

**Query Parameters:**
- `project_id` (optional): Filter by project ID
- `running` (optional): Filter running entries ("true")
- `billable` (optional): Filter billable entries ("true")
- `start_date` (optional): Filter by start date (YYYY-MM-DD)
- `end_date` (optional): Filter by end date (YYYY-MM-DD)
- `page` (optional, default: 1): Page number
- `per_page` (optional, default: 50, max: 100): Results per page

**Example:**
```bash
GET /api/v1/time_entries?project_id=5&start_date=2025-10-01&end_date=2025-10-31&page=1&per_page=50
```

**Response:**
```json
{
  "data": [
    {
      "id": 123,
      "project_id": 5,
      "project_name": "Client Project",
      "description": "Working on feature X",
      "started_at": "2025-10-15T10:30:00Z",
      "ended_at": "2025-10-15T12:30:00Z",
      "duration": 7200,
      "formatted_duration": "02:00:00",
      "billable": true,
      "billed": false,
      "running": false,
      "created_at": "2025-10-15T10:30:00Z",
      "updated_at": "2025-10-15T12:30:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 50
  }
}
```

#### Get Time Entry
```
GET /api/v1/time_entries/:id
```

Returns a single time entry.

#### Create Time Entry
```
POST /api/v1/time_entries
```

Creates a new time entry (for manual time entry, not timer).

**Parameters:**
- `project_id` (required): ID of the project
- `description` (optional): Description of the work
- `started_at` (required): Start time (ISO 8601)
- `ended_at` (optional): End time (ISO 8601)
- `billable` (optional, default: true): Whether the time is billable

**Request:**
```json
{
  "time_entry": {
    "project_id": 5,
    "description": "Working on feature X",
    "started_at": "2025-10-15T10:30:00Z",
    "ended_at": "2025-10-15T12:30:00Z",
    "billable": true
  }
}
```

#### Update Time Entry
```
PATCH /api/v1/time_entries/:id
```

Updates an existing time entry.

**Parameters:** Same as Create Time Entry

#### Delete Time Entry
```
DELETE /api/v1/time_entries/:id
```

Deletes a time entry. Returns 204 No Content on success.

#### Stop Time Entry
```
POST /api/v1/time_entries/:id/stop
```

Stops a specific running time entry (alternative to the general timer stop endpoint).

---

### Projects

#### List Projects
```
GET /api/v1/projects
```

Returns a list of projects for the current organization.

**Query Parameters:**
- `include_archived` (optional): Include archived projects ("true")
- `status` (optional): Filter by status (active, on_hold, completed, cancelled)

**Response:**
```json
{
  "data": [
    {
      "id": 5,
      "name": "Client Project",
      "description": "Main client project",
      "client_id": 2,
      "client_name": "Acme Corp",
      "hourly_rate": 150.0,
      "status": "active",
      "color": "#3b82f6",
      "archived": false,
      "created_at": "2025-01-01T00:00:00Z",
      "updated_at": "2025-10-15T00:00:00Z"
    }
  ]
}
```

#### Get Project
```
GET /api/v1/projects/:id
```

Returns a single project with statistics.

**Response:**
```json
{
  "data": {
    "id": 5,
    "name": "Client Project",
    "description": "Main client project",
    "client_id": 2,
    "client_name": "Acme Corp",
    "hourly_rate": 150.0,
    "status": "active",
    "color": "#3b82f6",
    "archived": false,
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-10-15T00:00:00Z",
    "stats": {
      "total_hours": 125.5,
      "unbilled_hours": 8.5,
      "total_revenue": 18825.0
    }
  }
}
```

#### Create Project
```
POST /api/v1/projects
```

Creates a new project.

**Parameters:**
- `name` (required): Project name
- `description` (optional): Project description
- `client_id` (optional): Client ID
- `hourly_rate` (optional): Hourly billing rate
- `status` (optional): Project status (active, on_hold, completed, cancelled)
- `color` (optional): Hex color code

**Request:**
```json
{
  "project": {
    "name": "New Project",
    "description": "A new client project",
    "client_id": 2,
    "hourly_rate": 150.0,
    "status": "active",
    "color": "#3b82f6"
  }
}
```

#### Update Project
```
PATCH /api/v1/projects/:id
```

Updates an existing project. Parameters same as Create Project.

---

## Rate Limits

Currently, there are no enforced rate limits, but please be considerate:
- Maximum 100 results per page for list endpoints
- Avoid polling endpoints more frequently than once per minute

## Error Codes

- `200 OK`: Request succeeded
- `201 Created`: Resource created successfully
- `204 No Content`: Resource deleted successfully
- `400 Bad Request`: Invalid request parameters
- `401 Unauthorized`: Invalid or missing API token
- `404 Not Found`: Resource not found
- `422 Unprocessable Entity`: Validation error

## Example Client Implementation (cURL)

### Start a timer
```bash
curl -X POST https://onepunch.work/api/v1/timer/start \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": 5,
    "description": "Working on API documentation",
    "billable": true
  }'
```

### List today's time entries
```bash
curl -X GET "https://onepunch.work/api/v1/time_entries?start_date=$(date +%Y-%m-%d)&end_date=$(date +%Y-%m-%d)" \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

### Stop the current timer
```bash
curl -X POST https://onepunch.work/api/v1/timer/stop \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

## Support

For issues or questions:
- GitHub: https://github.com/anthropics/onepunch/issues
- Documentation: https://docs.onepunch.work
