# OnePunch Style Guide

This document defines the design system and style guidelines for maintaining consistency across the OnePunch application.

## Layout & Container Standards

### Page Container Width
All pages use a consistent max-width container for content:
```erb
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <!-- Page content -->
</div>
```

### Card Components
Standard card structure with shadow and rounded corners:
```erb
<div class="bg-white shadow rounded-lg">
  <div class="px-6 py-4 border-b border-gray-200">
    <h2 class="text-lg font-medium text-gray-900">Card Title</h2>
  </div>
  <div class="p-6">
    <!-- Card content -->
  </div>
</div>
```

## Form Styling

### Input Fields
All text inputs, selects, and textareas should have consistent padding and borders:
```erb
<!-- Text Input -->
<%= form.text_field :name,
    class: "mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" %>

<!-- Select -->
<%= form.select :currency, options,
    class: "mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" %>

<!-- Textarea -->
<%= form.text_area :description,
    class: "mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm",
    rows: 4 %>
```

### Form Labels
```erb
<%= form.label :field_name, class: "block text-sm font-medium text-gray-700" %>
```

### Form Layout
```erb
<%= form_with(model: @model, local: true) do |form| %>
  <div class="p-6 space-y-6">
    <!-- Form fields with space-y-6 between groups -->
  </div>
  <div class="px-6 py-4 bg-gray-50 border-t border-gray-200 flex justify-end space-x-3">
    <!-- Form actions -->
  </div>
<% end %>
```

## Button Styles

### Primary Button (Indigo)
```erb
class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
```

### Secondary Button (Gray)
```erb
class="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
```

### Danger Button (Red)
```erb
class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
```

### Text Link Button
```erb
class="text-sm text-indigo-600 hover:text-indigo-500 font-medium"
```

## Typography

### Page Headers
```erb
<h1 class="text-3xl font-bold text-gray-900">Page Title</h1>
<p class="mt-2 text-sm text-gray-600">Page description or subtitle</p>
```

### Section Headers
```erb
<h2 class="text-xl font-semibold text-gray-900">Section Title</h2>
<h3 class="text-lg font-medium text-gray-900">Subsection Title</h3>
```

### Body Text
- Regular text: `text-sm text-gray-900`
- Secondary text: `text-sm text-gray-600`
- Muted text: `text-sm text-gray-500`
- Small/helper text: `text-xs text-gray-500`

## Status Badges

### Success/Active
```erb
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
  Active
</span>
```

### Warning/Trial
```erb
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
  Trial
</span>
```

### Danger/Expired
```erb
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
  Expired
</span>
```

### Info/Personal
```erb
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
  Personal
</span>
```

### Neutral/Default
```erb
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
  Business
</span>
```

## Alert Messages

### Success Alert
```erb
<div class="rounded-md bg-green-50 p-4">
  <div class="flex">
    <div class="flex-shrink-0">
      <svg class="h-5 w-5 text-green-400" fill="currentColor" viewBox="0 0 20 20">
        <!-- Check circle icon -->
      </svg>
    </div>
    <div class="ml-3">
      <p class="text-sm font-medium text-green-800">Success message</p>
    </div>
  </div>
</div>
```

### Error Alert
```erb
<div class="rounded-md bg-red-50 p-4">
  <div class="flex">
    <div class="ml-3">
      <h3 class="text-sm font-medium text-red-800">Error title</h3>
      <div class="mt-2 text-sm text-red-700">
        <ul class="list-disc space-y-1 pl-5">
          <li>Error detail</li>
        </ul>
      </div>
    </div>
  </div>
</div>
```

### Warning Alert
```erb
<div class="rounded-md bg-yellow-50 p-4">
  <div class="flex">
    <div class="flex-shrink-0">
      <svg class="h-5 w-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
        <!-- Warning icon -->
      </svg>
    </div>
    <div class="ml-3">
      <h3 class="text-sm font-medium text-yellow-800">Warning title</h3>
      <div class="mt-2 text-sm text-yellow-700">
        <p>Warning message</p>
      </div>
    </div>
  </div>
</div>
```

## Tables

### Standard Table
```erb
<div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
  <table class="min-w-full divide-y divide-gray-300">
    <thead class="bg-gray-50">
      <tr>
        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
          Column Header
        </th>
      </tr>
    </thead>
    <tbody class="bg-white divide-y divide-gray-200">
      <tr>
        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
          Cell content
        </td>
      </tr>
    </tbody>
  </table>
</div>
```

## Navigation

### Tab Navigation
```erb
<nav class="flex space-x-8">
  <!-- Active tab -->
  <a href="#" class="pb-3 px-1 border-b-2 font-medium text-sm border-indigo-500 text-indigo-600">
    Active Tab
  </a>
  <!-- Inactive tab -->
  <a href="#" class="pb-3 px-1 border-b-2 font-medium text-sm border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300">
    Inactive Tab
  </a>
</nav>
```

## Grid Layouts

### Cards Grid
```erb
<!-- Responsive grid: 1 column on mobile, 2 on medium, 3 on large -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <!-- Card items -->
</div>
```

### Two Column Layout
```erb
<div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
  <div class="lg:col-span-2">
    <!-- Main content (2/3 width) -->
  </div>
  <div>
    <!-- Sidebar (1/3 width) -->
  </div>
</div>
```

## Spacing Guidelines

### Section Spacing
- Between major sections: `mb-8` or `mt-8`
- Between cards in same section: `mt-6`
- Within cards: `space-y-6` for form fields, `space-y-4` for content

### Component Spacing
- Form field groups: `space-y-6`
- List items: `space-y-2` or `space-y-3`
- Button groups: `space-x-3`
- Inline elements: `space-x-2`

## Icons

Use Heroicons (https://heroicons.com/) for consistency:
```erb
<!-- Outline style for navigation -->
<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="..."/>
</svg>

<!-- Solid style for indicators -->
<svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
  <path fill-rule="evenodd" d="..." clip-rule="evenodd"/>
</svg>
```

## Dropdown Menus

```erb
<div class="relative" data-controller="dropdown">
  <button data-action="click->dropdown#toggle" class="...">
    Dropdown Trigger
  </button>
  <div data-dropdown-target="menu" class="hidden absolute right-0 mt-2 w-56 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 z-50">
    <div class="py-1">
      <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
        Menu Item
      </a>
    </div>
  </div>
</div>
```

## Mobile Responsive Patterns

### Responsive Padding
```erb
class="px-4 sm:px-6 lg:px-8"
```

### Responsive Text Size
```erb
class="text-sm sm:text-base"
```

### Responsive Grid
```erb
class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3"
```

### Hide/Show Elements
```erb
<!-- Hidden on mobile, shown on medium+ -->
class="hidden md:block"

<!-- Shown on mobile, hidden on medium+ -->
class="block md:hidden"
```

## Color Palette

### Primary (Indigo)
- Background: `bg-indigo-600` hover: `bg-indigo-700`
- Text: `text-indigo-600` hover: `text-indigo-500`
- Border: `border-indigo-500`
- Focus ring: `focus:ring-indigo-500`

### Neutral (Gray)
- Background: `bg-gray-50`, `bg-gray-100`, `bg-gray-200`
- Text: `text-gray-500`, `text-gray-600`, `text-gray-700`, `text-gray-900`
- Border: `border-gray-200`, `border-gray-300`

### Semantic Colors
- Success: Green (`bg-green-100`, `text-green-800`)
- Warning: Yellow (`bg-yellow-100`, `text-yellow-800`)
- Error: Red (`bg-red-100`, `text-red-800`)
- Info: Blue (`bg-blue-100`, `text-blue-800`)

## Accessibility

### Focus States
All interactive elements must have visible focus states:
```erb
class="focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
```

### ARIA Labels
Add appropriate ARIA labels for screen readers:
```erb
<button aria-label="Close dialog">
  <svg aria-hidden="true">...</svg>
</button>
```

### Form Accessibility
- Always associate labels with form controls
- Provide helpful error messages
- Use proper semantic HTML elements

## Animation & Transitions

### Hover Transitions
```erb
class="transition-colors duration-200"
class="transition-shadow duration-200"
```

### Common Transitions
- Shadow on hover: `hover:shadow-md transition-shadow duration-200`
- Color change: `hover:text-indigo-500 transition-colors`
- Background change: `hover:bg-gray-50 transition-colors`

## Code Organization

### Partial Naming
- Prefix with underscore: `_navbar.html.erb`
- Use descriptive names: `_organization_switcher.html.erb`
- Group related partials in subdirectories

### CSS Class Order
1. Display & Position (`block`, `absolute`, `flex`)
2. Spacing (`p-4`, `m-2`, `space-y-4`)
3. Sizing (`w-full`, `h-12`, `max-w-7xl`)
4. Typography (`text-sm`, `font-medium`)
5. Colors (`bg-white`, `text-gray-900`)
6. Borders (`border`, `rounded-lg`)
7. Effects (`shadow`, `opacity-50`)
8. Interactions (`hover:`, `focus:`)
9. Responsive (`sm:`, `md:`, `lg:`)

## Testing Considerations

When adding new UI components:
1. Test responsive behavior on mobile, tablet, and desktop
2. Verify keyboard navigation works properly
3. Check color contrast for accessibility
4. Test with Turbo enabled/disabled
5. Verify form validations display correctly

## Maintenance

This style guide should be updated when:
- New component patterns are introduced
- Existing patterns are modified
- Accessibility improvements are made
- New color schemes or states are added

Always reference this guide when:
- Creating new views or components
- Refactoring existing UI code
- Reviewing pull requests
- Onboarding new developers