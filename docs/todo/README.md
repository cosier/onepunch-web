# Active TODO Items

This directory contains active work items and implementation tasks currently in progress or planned for near-term execution.

## Current TODOs

| #  | Name | Status | Description |
|----|------|--------|-------------|
| 01 | [MVP Launch](01-mvp-launch.md) | 🟡 Partial | Core MVP features for time tracking & invoicing |
| 02 | [Multi-Org Filtering](02-multi-org-filtering.md) | 🟡 In Progress | Time entries filtering across multiple organizations |

## Status Legend

- 🟢 **Complete** - Task finished and verified
- 🟡 **In Progress** - Currently being worked on
- 🔴 **Blocked** - Waiting on dependencies
- ⚪ **Planned** - Not yet started

## Workflow

### Adding New TODOs

1. Create a new file with format: `NN-feature-name.md`
2. Use the next available number (03, 04, etc.)
3. Include the following sections:
   - **Overview**: Brief description
   - **Status**: Current progress
   - **Tasks**: Checklist of implementation steps
   - **Notes**: Important considerations

### Completing TODOs

When a TODO is completed:

1. Update the status in this README to 🟢 Complete
2. Add completion date to the TODO file
3. Move the file to `docs/completed/`
4. Update `docs/completed/README.md` with the entry

### Example TODO Template

```markdown
# TODO NN: Feature Name

## Overview
Brief description of what needs to be done.

## Status
- Started: YYYY-MM-DD
- Current: In Progress / Blocked / Planned
- Completed: YYYY-MM-DD (when done)

## Tasks
- [ ] Task 1
- [ ] Task 2
- [x] Completed task

## Dependencies
- Depends on TODO XX
- Requires feature Y

## Notes
Important considerations and context.
```

## Guidelines

- Keep TODOs focused on implementation work
- Use `docs/planning/` for architecture and design discussions
- Move completed items to `docs/completed/` promptly
- Reference related planning docs when relevant
- Update this README whenever TODOs are added/removed/completed
