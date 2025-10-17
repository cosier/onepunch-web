import { Controller } from "@hotwired/stimulus"

// Handles time entries filtering with dynamic organization and project updates
export default class extends Controller {
  static targets = ["organizationSelect", "projectSelect", "form"]
  static values = {
    projectsByOrg: Object  // JSON structure: { "org_id": { name: "Org Name", projects: [...] } }
  }

  connect() {
    this.updateProjectOptions()
  }

  // Called when organization selection changes
  organizationChanged(event) {
    this.updateProjectOptions()
    this.submitForm()
  }

  // Called when project selection changes
  projectChanged(event) {
    this.submitForm()
  }

  // Dynamically update project dropdown based on selected organizations
  updateProjectOptions() {
    if (!this.hasProjectSelectTarget) return

    // Get selected organization IDs from SlimSelect controller
    const orgSlimSelect = this.application.getControllerForElementAndIdentifier(
      this.organizationSelectTarget,
      "slim-select"
    )

    if (!orgSlimSelect) return

    const selectedOrgIds = orgSlimSelect.getSelected()

    // Build new options with optgroups
    const newOptions = [{ text: "All projects", value: "" }]

    selectedOrgIds.forEach(orgId => {
      const orgData = this.projectsByOrgValue[orgId]
      if (!orgData || !orgData.projects || orgData.projects.length === 0) return

      // Add optgroup for this organization
      const optgroup = {
        label: orgData.name,
        options: orgData.projects.map(project => ({
          text: project.name,
          value: project.id.toString()
        }))
      }

      newOptions.push(optgroup)
    })

    // Update the project select with new options
    const projectSlimSelect = this.application.getControllerForElementAndIdentifier(
      this.projectSelectTarget,
      "slim-select"
    )

    if (projectSlimSelect) {
      const currentValue = projectSlimSelect.getSelected()[0] || ""
      projectSlimSelect.setData(newOptions)

      // Try to preserve selection if it's still available
      const isStillAvailable = newOptions.some(opt => {
        if (opt.options) {
          return opt.options.some(o => o.value === currentValue)
        }
        return opt.value === currentValue
      })

      if (isStillAvailable) {
        projectSlimSelect.setSelected([currentValue])
      } else {
        projectSlimSelect.setSelected([""])
      }
    }
  }

  // Submit the form to filter results
  submitForm() {
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }
  }

  // Clear all filters and reset to current organization
  clearFilters(event) {
    event.preventDefault()

    // Clear all select elements
    if (this.hasOrganizationSelectTarget) {
      const orgSlimSelect = this.application.getControllerForElementAndIdentifier(
        this.organizationSelectTarget,
        "slim-select"
      )
      if (orgSlimSelect) {
        orgSlimSelect.setSelected([])
      }
    }

    if (this.hasProjectSelectTarget) {
      const projectSlimSelect = this.application.getControllerForElementAndIdentifier(
        this.projectSelectTarget,
        "slim-select"
      )
      if (projectSlimSelect) {
        projectSlimSelect.setSelected([""])
      }
    }

    // Submit to reload with defaults
    this.submitForm()
  }
}