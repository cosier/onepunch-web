# TODO 02: Multi-Organization Time Entries Filtering

## Overview
Refactor the time entries page to allow users full access to their time entries across all organizations, with intelligent filtering by organization(s) and dynamically-filtered projects.

## Status: In Progress
Started: 2025-09-30

## Key Features
1. **Multi-select Organization Filter** using SlimSelect
   - Default: Current active organization pre-selected
   - Allow clearing to show ALL time entries from all organizations
   - Multiple organizations can be selected simultaneously

2. **Dynamic Project Filter**
   - Updates available projects based on selected organization(s)
   - Custom rendering with organization labels using optgroup grouping
   - Respects organization filter selections

3. **Remove Hard Organization Scoping**
   - Allow users to view ALL their time entries across organizations
   - Maintain data security (user can only see their own entries)

## Implementation Tasks

### Phase 1: Backend Infrastructure
- [ ] Install SlimSelect via importmap
- [ ] Update TimeEntriesController to remove hard org scoping
- [ ] Add `organization_ids[]` parameter handling
- [ ] Create projects API endpoint for dynamic loading
- [ ] Update security validations for multi-org access

### Phase 2: Frontend Components
- [ ] Create SlimSelect Stimulus controller (reusable)
- [ ] Create TimeEntriesFilter Stimulus controller
- [ ] Update time entries index view with new filters
- [ ] Implement dynamic project dropdown updates
- [ ] Add loading states and transitions

### Phase 3: Data & Security
- [ ] Ensure proper data scoping (user can only see their entries)
- [ ] Validate organization_ids belong to current_user
- [ ] Validate project_ids belong to user's organizations
- [ ] Test authorization for edit/delete actions

### Phase 4: UX Polish
- [ ] Preserve filter state in URL parameters
- [ ] Add "Clear Filters" functionality
- [ ] Improve visual feedback during filtering
- [ ] Test browser back/forward behavior
- [ ] Mobile responsive design

## Technical Details

### Projects JSON Structure
```javascript
{
  "1": [ // organization_id
    { id: 1, name: "Project A", color: "#abc123", organization_name: "Acme Corp" },
    { id: 2, name: "Project B", color: "#def456", organization_name: "Acme Corp" }
  ],
  "2": [
    { id: 3, name: "Project C", color: "#789abc", organization_name: "Personal Org." }
  ]
}
```

### Project Select Rendering (OptGroup)
```html
<select name="project_id">
  <option value="">All projects</option>
  <optgroup label="Acme Corp">
    <option value="1">Project A</option>
    <option value="2">Project B</option>
  </optgroup>
  <optgroup label="Personal Org.">
    <option value="3">Project C</option>
  </optgroup>
</select>
```

### Controller Action Signature
```ruby
def index
  # Get selected organizations (default to current if none selected)
  selected_org_ids = params[:organization_ids].presence || [current_organization&.id].compact

  # Validate user has access to these organizations
  valid_org_ids = current_user.organizations.where(id: selected_org_ids).pluck(:id)

  # Get all projects from valid organizations
  all_project_ids = Project.where(organization_id: valid_org_ids).pluck(:id)

  # Filter time entries
  @time_entries = current_user.time_entries
    .where(project_id: all_project_ids)
    .recent
    .includes(:project)

  # Apply additional filters
  @time_entries = @time_entries.where(project_id: params[:project_id]) if params[:project_id].present?
  @time_entries = @time_entries.where("DATE(started_at) = ?", params[:date]) if params[:date].present?
end
```

## Files to Create/Modify

### New Files
- [x] `docs/todo_02.md` - This file
- [ ] `app/javascript/controllers/slim_select_controller.js`
- [ ] `app/javascript/controllers/time_entries_filter_controller.js`

### Modified Files
- [ ] `config/importmap.rb` - Add SlimSelect
- [ ] `app/assets/stylesheets/application.css` - Add SlimSelect CSS
- [ ] `app/controllers/time_entries_controller.rb` - Multi-org filtering
- [ ] `app/views/time_entries/index.html.erb` - New filter UI
- [ ] `config/routes.rb` - Add projects API endpoint (if needed)

## Testing Checklist
- [ ] User can see all time entries when no org selected
- [ ] User can filter by single organization
- [ ] User can filter by multiple organizations
- [ ] Projects update correctly when orgs change
- [ ] Project filter works with org filter
- [ ] Date filter works alongside new filters
- [ ] Clear filters resets to default (current org)
- [ ] URL parameters preserve filter state
- [ ] Security: User cannot see other users' entries
- [ ] Security: User cannot filter by orgs they don't belong to
- [ ] Browser back/forward button works correctly
- [ ] Mobile responsive layout

## Edge Cases to Handle
- User belongs to only one organization
- User has no projects in selected organization(s)
- User has no time entries matching filters
- Very large number of organizations/projects
- No organizations selected (show all)
- Invalid organization IDs in parameters

## Notes
- Using OptGroup approach for better organization of projects
- SlimSelect chosen for better UX than native multi-select
- Maintaining backward compatibility with existing filters
- Security is paramount - user can only access their own data

## Future Enhancements (Not in Scope)
- Save filter preferences per user
- Add date range picker
- Add billable/non-billable filter
- Add description search
- Export filtered results to CSV
- Keyboard shortcuts for filters