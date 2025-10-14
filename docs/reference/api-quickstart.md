# OnePunch API Quick Start Guide

## Getting Your API Token

### Via Web Interface (Coming Soon)
Settings → Account → API Token section

### Via Rails Console
```ruby
rails console
user = User.find_by(email: 'your@email.com')
puts user.api_token
```

## Quick Examples

### 1. Check Your User Info
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://onepunch.work/api/v1/users/me
```

### 2. List Your Projects
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://onepunch.work/api/v1/projects
```

### 3. Start a Timer
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"project_id": 1, "description": "Working on feature", "billable": true}' \
  https://onepunch.work/api/v1/timer/start
```

### 4. Check Current Timer
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://onepunch.work/api/v1/timer/current
```

### 5. Stop Timer
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  https://onepunch.work/api/v1/timer/stop
```

### 6. List Time Entries (Today)
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "https://onepunch.work/api/v1/time_entries?start_date=$(date +%Y-%m-%d)&end_date=$(date +%Y-%m-%d)"
```

### 7. Create Manual Time Entry
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "time_entry": {
      "project_id": 1,
      "description": "Meeting with client",
      "started_at": "2025-10-15T09:00:00Z",
      "ended_at": "2025-10-15T10:00:00Z",
      "billable": true
    }
  }' \
  https://onepunch.work/api/v1/time_entries
```

## Using Test Script

We've included a test script to verify your API access:

```bash
# Make script executable (first time only)
chmod +x test_api.sh

# Run tests
API_TOKEN=your_token_here ./test_api.sh
```

## Multiple Organizations

If you belong to multiple organizations, specify which one to use:

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     -H "X-Organization-ID: 123" \
     https://onepunch.work/api/v1/projects
```

## Building a Client

### Authentication
Store the API token securely and include it in every request:
```
Authorization: Bearer YOUR_TOKEN
```

### Recommended Flow

1. **Initialize**: Get user info and organizations
   ```
   GET /api/v1/users/me
   ```

2. **Load Projects**: Get available projects for time tracking
   ```
   GET /api/v1/projects
   ```

3. **Start Tracking**: Start timer when user begins work
   ```
   POST /api/v1/timer/start
   ```

4. **Check Status**: Periodically check if timer is running (max 1/minute)
   ```
   GET /api/v1/timer/current
   ```

5. **Stop Tracking**: Stop timer when done
   ```
   POST /api/v1/timer/stop
   ```

6. **View History**: List time entries with filters
   ```
   GET /api/v1/time_entries?start_date=2025-10-01&end_date=2025-10-31
   ```

## Error Handling

```json
// Success (200 OK)
{
  "data": { ... }
}

// Error (401 Unauthorized)
{
  "error": "Invalid or missing API token"
}

// Validation Error (422)
{
  "error": "Validation failed",
  "details": ["Project must exist", "Description can't be blank"]
}
```

## Rate Limiting

- Be respectful: Don't poll more than once per minute
- Maximum 100 results per page
- No hard rate limits currently enforced

## Need Help?

- Full API Documentation: `docs/API.md`
- Test your setup: `./test_api.sh`
- Report issues: GitHub Issues
