# Organization API Documentation

## Overview
This document defines all API endpoints related to organization management, both for internal Rails controllers and external API consumers (mobile app, integrations).

## Authentication
All endpoints require authentication via:
- Session cookie (web)
- Bearer token (API)
- JWT for mobile apps

## Base URL
- Development: `http://localhost:3000/api/v1`
- Production: `https://api.onepunch.work/v1`

## Response Format
All API responses follow this structure:

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "timestamp": "2024-01-15T10:30:00Z",
    "version": "1.0"
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "ORG_NOT_FOUND",
    "message": "Organization not found",
    "details": { ... }
  },
  "meta": { ... }
}
```

## Organization Endpoints

### 1. List User's Organizations
**GET** `/api/v1/organizations`

Returns all organizations the current user belongs to.

**Response:**
```json
{
  "success": true,
  "data": {
    "organizations": [
      {
        "id": "org_123",
        "name": "Acme Inc",
        "slug": "acme-inc",
        "logo_url": "https://...",
        "role": "owner",
        "is_current": true,
        "member_count": 5,
        "created_at": "2024-01-01T00:00:00Z"
      }
    ],
    "current_organization_id": "org_123"
  }
}
```

### 2. Get Organization Details
**GET** `/api/v1/organizations/:id`

**Parameters:**
- `include` (optional): Comma-separated list of related data
  - `members` - Include organization members
  - `projects` - Include active projects
  - `stats` - Include usage statistics

**Response:**
```json
{
  "success": true,
  "data": {
    "organization": {
      "id": "org_123",
      "name": "Acme Inc",
      "slug": "acme-inc",
      "logo_url": "https://...",
      "website": "https://acme.com",
      "industry": "technology",
      "size": "medium",
      "billing_email": "billing@acme.com",
      "address": "123 Main St...",
      "timezone": "America/New_York",
      "currency": "USD",
      "tax_id": "12-3456789",
      "onboarded_at": "2024-01-01T10:00:00Z",
      "subscription_status": "active",
      "trial_ends_at": null,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-15T00:00:00Z"
    },
    "members": [...],
    "projects": [...],
    "stats": {
      "total_hours_this_month": 320.5,
      "active_projects": 12,
      "total_revenue_this_month": 48075.00,
      "pending_invoices": 3
    }
  }
}
```

### 3. Create Organization
**POST** `/api/v1/organizations`

**Request Body:**
```json
{
  "organization": {
    "name": "New Company",
    "industry": "consulting",
    "size": "small",
    "website": "https://newcompany.com",
    "billing_email": "billing@newcompany.com",
    "timezone": "UTC",
    "currency": "USD"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "organization": { ... },
    "membership": {
      "id": "mem_456",
      "role": "owner",
      "joined_at": "2024-01-15T10:30:00Z"
    }
  }
}
```

### 4. Update Organization
**PATCH** `/api/v1/organizations/:id`

**Request Body:**
```json
{
  "organization": {
    "name": "Updated Name",
    "logo": "[base64_encoded_image]",
    "billing_email": "new-billing@company.com"
  }
}
```

### 5. Delete Organization
**DELETE** `/api/v1/organizations/:id`

Only owners can delete organizations. Requires confirmation token.

**Request Body:**
```json
{
  "confirmation_token": "DELETE-org_123",
  "transfer_data": true
}
```

### 6. Switch Active Organization
**POST** `/api/v1/organizations/:id/switch`

Sets the specified organization as the current active organization.

**Response:**
```json
{
  "success": true,
  "data": {
    "previous_organization_id": "org_122",
    "current_organization_id": "org_123",
    "switched_at": "2024-01-15T10:35:00Z"
  }
}
```

## Membership Endpoints

### 7. List Organization Members
**GET** `/api/v1/organizations/:organization_id/members`

**Query Parameters:**
- `role`: Filter by role (owner, admin, member)
- `status`: active, invited, suspended
- `sort`: name, joined_at, last_active
- `page`: Page number (default: 1)
- `per_page`: Items per page (default: 25)

**Response:**
```json
{
  "success": true,
  "data": {
    "members": [
      {
        "id": "mem_789",
        "user": {
          "id": "user_456",
          "email": "john@acme.com",
          "first_name": "John",
          "last_name": "Doe",
          "avatar_url": "https://...",
          "last_sign_in_at": "2024-01-15T09:00:00Z"
        },
        "role": "admin",
        "joined_at": "2024-01-01T00:00:00Z",
        "invited_by": {
          "id": "user_123",
          "name": "Jane Smith"
        },
        "permissions": ["manage_projects", "view_reports", "manage_members"]
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 3,
      "total_count": 65,
      "per_page": 25
    }
  }
}
```

### 8. Add Member to Organization
**POST** `/api/v1/organizations/:organization_id/members`

**Request Body:**
```json
{
  "member": {
    "email": "newmember@example.com",
    "role": "member",
    "send_invitation": true,
    "personal_message": "Welcome to our team!"
  }
}
```

### 9. Update Member Role
**PATCH** `/api/v1/organizations/:organization_id/members/:id`

**Request Body:**
```json
{
  "member": {
    "role": "admin"
  }
}
```

### 10. Remove Member from Organization
**DELETE** `/api/v1/organizations/:organization_id/members/:id`

**Query Parameters:**
- `reassign_to`: User ID to reassign ownership of projects/data
- `delete_data`: Boolean to delete all user's data (requires owner role)

## Invitation Endpoints

### 11. Create Invitation
**POST** `/api/v1/organizations/:organization_id/invitations`

**Request Body:**
```json
{
  "invitations": [
    {
      "email": "user1@example.com",
      "role": "member",
      "personal_message": "Join our team!"
    },
    {
      "email": "user2@example.com",
      "role": "admin"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "invitations": [
      {
        "id": "inv_001",
        "email": "user1@example.com",
        "role": "member",
        "token": "abc123...",
        "expires_at": "2024-01-22T10:35:00Z",
        "invitation_url": "https://app.onepunch.work/join?token=abc123..."
      }
    ],
    "bulk_invitation_url": "https://app.onepunch.work/join?org=org_123"
  }
}
```

### 12. List Pending Invitations
**GET** `/api/v1/organizations/:organization_id/invitations`

**Query Parameters:**
- `status`: pending, accepted, expired
- `sort`: created_at, expires_at

### 13. Resend Invitation
**POST** `/api/v1/organizations/:organization_id/invitations/:id/resend`

### 14. Revoke Invitation
**DELETE** `/api/v1/organizations/:organization_id/invitations/:id`

### 15. Accept Invitation
**POST** `/api/v1/invitations/accept`

**Request Body:**
```json
{
  "token": "abc123...",
  "user": {
    "first_name": "John",
    "last_name": "Doe",
    "password": "SecurePassword123!",
    "password_confirmation": "SecurePassword123!"
  }
}
```

## Organization Settings

### 16. Get Organization Settings
**GET** `/api/v1/organizations/:id/settings`

Returns all configurable settings for the organization.

**Response:**
```json
{
  "success": true,
  "data": {
    "settings": {
      "general": {
        "name": "Acme Inc",
        "slug": "acme-inc",
        "website": "https://acme.com"
      },
      "billing": {
        "billing_email": "billing@acme.com",
        "tax_id": "12-3456789",
        "address": { ... },
        "currency": "USD"
      },
      "features": {
        "time_tracking": true,
        "invoicing": true,
        "project_templates": true,
        "api_access": true,
        "sso_enabled": false
      },
      "notifications": {
        "daily_summary": true,
        "weekly_report": true,
        "invoice_reminders": true,
        "member_activity": false
      },
      "integrations": [
        {
          "name": "slack",
          "enabled": true,
          "config": { ... }
        }
      ]
    }
  }
}
```

### 17. Update Organization Settings
**PATCH** `/api/v1/organizations/:id/settings`

**Request Body:**
```json
{
  "settings": {
    "notifications": {
      "daily_summary": false
    },
    "features": {
      "sso_enabled": true
    }
  }
}
```

## Organization Statistics

### 18. Get Organization Statistics
**GET** `/api/v1/organizations/:id/stats`

**Query Parameters:**
- `period`: today, week, month, quarter, year, custom
- `start_date`: YYYY-MM-DD (for custom period)
- `end_date`: YYYY-MM-DD (for custom period)
- `group_by`: day, week, month
- `include`: projects, members, clients

**Response:**
```json
{
  "success": true,
  "data": {
    "stats": {
      "period": {
        "start": "2024-01-01",
        "end": "2024-01-31"
      },
      "summary": {
        "total_hours": 640.5,
        "billable_hours": 580.25,
        "total_revenue": 87037.50,
        "active_projects": 8,
        "active_members": 12
      },
      "time_series": [
        {
          "date": "2024-01-01",
          "hours": 24.5,
          "revenue": 3675.00
        }
      ],
      "by_project": [
        {
          "project_id": "proj_123",
          "project_name": "Website Redesign",
          "hours": 120.5,
          "revenue": 18075.00
        }
      ],
      "by_member": [
        {
          "user_id": "user_456",
          "user_name": "John Doe",
          "hours": 160.0,
          "projects_count": 3
        }
      ]
    }
  }
}
```

## Onboarding Endpoints

### 19. Get Onboarding Status
**GET** `/api/v1/organizations/:id/onboarding`

**Response:**
```json
{
  "success": true,
  "data": {
    "onboarding": {
      "completed": false,
      "started_at": "2024-01-15T10:00:00Z",
      "current_step": 3,
      "total_steps": 5,
      "steps_completed": {
        "organization_created": true,
        "first_project": true,
        "team_invited": false,
        "billing_setup": false,
        "tour_completed": false
      },
      "checklist": [
        {
          "key": "organization_logo",
          "label": "Add organization logo",
          "completed": false,
          "optional": true
        }
      ]
    }
  }
}
```

### 20. Update Onboarding Progress
**PATCH** `/api/v1/organizations/:id/onboarding`

**Request Body:**
```json
{
  "onboarding": {
    "current_step": 4,
    "steps_completed": {
      "team_invited": true
    }
  }
}
```

### 21. Complete Onboarding
**POST** `/api/v1/organizations/:id/onboarding/complete`

Marks onboarding as complete and triggers any post-onboarding actions.

## Webhooks

Organizations can register webhooks for events:

### 22. Register Webhook
**POST** `/api/v1/organizations/:id/webhooks`

**Request Body:**
```json
{
  "webhook": {
    "url": "https://example.com/webhook",
    "events": ["member.added", "member.removed", "project.created"],
    "secret": "webhook_secret_key"
  }
}
```

### Available Webhook Events:
- `organization.created`
- `organization.updated`
- `organization.deleted`
- `member.added`
- `member.removed`
- `member.role_changed`
- `invitation.sent`
- `invitation.accepted`
- `project.created`
- `project.archived`
- `invoice.created`
- `invoice.paid`

## Rate Limiting

API endpoints are rate limited:
- **Standard tier**: 100 requests/minute
- **Pro tier**: 500 requests/minute
- **Enterprise**: Unlimited

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1705316400
```

## Error Codes

### Organization Errors
- `ORG_NOT_FOUND` - Organization does not exist
- `ORG_ACCESS_DENIED` - User lacks permission
- `ORG_QUOTA_EXCEEDED` - Organization limit reached
- `ORG_SUSPENDED` - Organization is suspended
- `ORG_INVALID_NAME` - Invalid organization name
- `ORG_DUPLICATE_SLUG` - Slug already exists

### Membership Errors
- `MEMBER_NOT_FOUND` - Member does not exist
- `MEMBER_ALREADY_EXISTS` - User is already a member
- `MEMBER_CANNOT_REMOVE_OWNER` - Cannot remove organization owner
- `MEMBER_INSUFFICIENT_PERMISSIONS` - Lacks required permissions

### Invitation Errors
- `INVITATION_EXPIRED` - Invitation has expired
- `INVITATION_ALREADY_ACCEPTED` - Invitation was already accepted
- `INVITATION_INVALID_TOKEN` - Invalid invitation token
- `INVITATION_LIMIT_EXCEEDED` - Too many pending invitations

## SDK Examples

### JavaScript/TypeScript
```typescript
import { OnePunchAPI } from '@onepunch/sdk';

const api = new OnePunchAPI({
  apiKey: 'your-api-key',
  organizationId: 'org_123'
});

// List organizations
const orgs = await api.organizations.list();

// Switch organization
await api.organizations.switch('org_456');

// Invite members
await api.members.invite([
  { email: 'john@example.com', role: 'member' },
  { email: 'jane@example.com', role: 'admin' }
]);

// Get statistics
const stats = await api.organizations.stats('org_123', {
  period: 'month',
  include: ['projects', 'members']
});
```

### Ruby
```ruby
require 'onepunch'

client = OnePunch::Client.new(
  api_key: 'your-api-key',
  organization_id: 'org_123'
)

# List organizations
orgs = client.organizations.list

# Create organization
org = client.organizations.create(
  name: 'New Org',
  industry: 'technology'
)

# Add member
client.members.add(
  organization_id: org.id,
  email: 'newmember@example.com',
  role: 'member'
)
```

### Python
```python
from onepunch import Client

client = Client(
    api_key='your-api-key',
    organization_id='org_123'
)

# List organizations
orgs = client.organizations.list()

# Get statistics
stats = client.organizations.stats(
    'org_123',
    period='month',
    group_by='week'
)

# Invite members
invitations = client.invitations.create([
    {'email': 'user1@example.com', 'role': 'member'},
    {'email': 'user2@example.com', 'role': 'admin'}
])
```

## GraphQL Alternative

For more flexible querying, a GraphQL endpoint is available:

**POST** `/api/graphql`

```graphql
query GetOrganizationWithProjects {
  organization(id: "org_123") {
    id
    name
    members {
      edges {
        node {
          id
          user {
            email
            fullName
          }
          role
        }
      }
    }
    projects(first: 10, filter: { status: ACTIVE }) {
      edges {
        node {
          id
          name
          hourlyRate
          totalHours
        }
      }
    }
  }
}
```

## Testing

Use these test organization IDs in development:
- `org_test_001` - Basic organization
- `org_test_002` - Organization with 50+ members
- `org_test_003` - Organization at plan limits
- `org_test_suspended` - Suspended organization

Test API key: `test_key_development_only`

## Changelog

### Version 1.1 (Upcoming)
- Add bulk operations for members
- Organization templates
- Advanced permissions system
- Audit log API

### Version 1.0 (Current)
- Initial organization API
- Member management
- Invitation system
- Basic statistics