# Planning Documents

This directory contains architectural designs, feature specifications, and long-term planning documents for the OnePunch application.

## Current Planning Documents

| Document | Type | Status | Description |
|----------|------|--------|-------------|
| [Organization System](organization-system.md) | Architecture | ✅ Implemented | Multi-tenant organization system design |
| [Onboarding Wizard](onboarding-wizard.md) | Feature Spec | ✅ Implemented | User onboarding flow specification |
| [Organization API](organization-api.md) | API Spec | 📋 Partial | REST API for organization management |
| [Implementation Checklist](implementation-checklist.md) | Checklist | 🔄 Ongoing | Step-by-step implementation guide |
| [CORS Configuration](cors.md) | Config | 🔴 **BLOCKING** | CORS setup required for Desktop OAuth |

## Document Types

### Architecture Documents
High-level system design, database schema, and technical decisions.
- Focus on the "why" and "how" of major features
- Include diagrams, data models, and relationships
- Document trade-offs and alternatives considered

### Feature Specifications
Detailed specifications for new features before implementation.
- User stories and acceptance criteria
- UI/UX mockups and flows
- API contracts and data structures
- Edge cases and error handling

### API Specifications
Documentation for internal and external APIs.
- Endpoint definitions
- Request/response formats
- Authentication and authorization
- Rate limiting and error codes
- SDK examples

### Checklists
Step-by-step implementation guides for complex features.
- Ordered task lists
- Dependencies and prerequisites
- Testing requirements
- Deployment considerations

## Status Legend

- ✅ **Implemented** - Feature is live in production
- 🔄 **Ongoing** - Actively being worked on or evolving
- 📋 **Partial** - Some parts implemented, others planned
- 💡 **Proposed** - Idea stage, not yet approved
- ❌ **Deprecated** - No longer relevant or replaced

## Workflow

### Creating New Planning Documents

1. Start with a clear goal and scope
2. Use descriptive kebab-case filenames
3. Include these sections:
   - **Overview** - What and why
   - **Requirements** - What's needed
   - **Design** - How it works
   - **Implementation** - Steps to build
   - **Testing** - How to verify
   - **Deployment** - How to release

### From Planning to Implementation

1. Planning doc approved → Create corresponding TODO in `docs/todo/`
2. Reference planning doc from TODO
3. Keep planning doc updated with learnings during implementation
4. Mark as "Implemented" when live

### Maintaining Planning Docs

- Update status in this README regularly
- Archive deprecated docs to `docs/completed/`
- Keep docs up-to-date with current implementation
- Document deviations from original plans

## Guidelines

- Planning docs are living documents - update them as implementation progresses
- Include diagrams and code examples where helpful
- Cross-reference related planning docs and TODOs
- Focus on "why" decisions were made for future reference
- Consider mobile, API, and security implications in all plans
