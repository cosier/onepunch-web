import { Controller } from "@hotwired/stimulus"
import SlimSelect from "slim-select"

// Asana task selector with searchable dropdown and nested optgroups
// Extends SlimSelect to fetch tasks from API and build nested structure
export default class extends Controller {
  static targets = ["select"]
  static values = {
    url: String,
    placeholder: { type: String, default: "Select an Asana task (optional)..." },
    searchPlaceholder: { type: String, default: "Search tasks..." }
  }

  connect() {
    this.initializeSlimSelect()
    this.loadTasks()
  }

  disconnect() {
    if (this.slimselect) {
      this.slimselect.destroy()
    }
  }

  initializeSlimSelect() {
    const selectElement = this.hasSelectTarget ? this.selectTarget : this.element

    this.slimselect = new SlimSelect({
      select: selectElement,
      settings: {
        placeholderText: this.placeholderValue,
        allowDeselect: true,
        closeOnSelect: true,
        searchText: "No tasks found",
        searchPlaceholder: this.searchPlaceholderValue,
        searchHighlight: true
      },
      events: {
        afterChange: (newVal) => {
          // Dispatch custom event for parent controllers
          this.dispatch("change", { detail: { values: newVal } })

          // Trigger native change event for form submissions
          const event = new Event('change', { bubbles: true })
          selectElement.dispatchEvent(event)
        },
        search: (search) => {
          // Custom search function to filter tasks
          return this.filterTasks(search)
        }
      }
    })
  }

  async loadTasks() {
    if (!this.hasUrlValue) {
      console.warn("AsanaTaskSelect: No URL provided")
      return
    }

    try {
      const response = await fetch(this.urlValue)

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()

      if (data.success && data.grouped_tasks) {
        this.buildNestedOptions(data.grouped_tasks)
      } else {
        console.warn("AsanaTaskSelect: No tasks found", data)
      }
    } catch (error) {
      console.error("AsanaTaskSelect: Failed to load tasks", error)
      this.showError("Failed to load Asana tasks")
    }
  }

  buildNestedOptions(groupedTasks) {
    const options = [
      {
        text: this.placeholderValue,
        value: '',
        placeholder: true
      }
    ]

    // Build nested structure: Workspace > Project > Tasks
    Object.entries(groupedTasks).forEach(([workspaceName, projects]) => {
      const workspaceOptgroup = {
        label: workspaceName,
        options: []
      }

      Object.entries(projects).forEach(([projectName, tasks]) => {
        // For SlimSelect, we can't do nested optgroups
        // So we'll prefix task labels with project name
        tasks.forEach(task => {
          workspaceOptgroup.options.push({
            text: `${projectName}: ${task.label}`,
            value: task.value,
            data: {
              workspace: workspaceName,
              project: projectName,
              completed: task.completed,
              dueDate: task.due_date
            }
          })
        })
      })

      if (workspaceOptgroup.options.length > 0) {
        options.push(workspaceOptgroup)
      }
    })

    // Update SlimSelect with new options
    if (this.slimselect) {
      this.slimselect.setData(options)
    }
  }

  filterTasks(searchTerm) {
    // This method is called by SlimSelect's search functionality
    // Return a promise that resolves to filtered options
    return new Promise((resolve) => {
      if (!searchTerm || searchTerm.length < 2) {
        resolve(this.slimselect.getData())
        return
      }

      const lowerSearch = searchTerm.toLowerCase()
      const allData = this.slimselect.getData()

      const filtered = allData.filter(item => {
        if (item.placeholder) return false

        if (item.label) {
          // This is an optgroup
          const filteredOptions = item.options.filter(opt =>
            opt.text.toLowerCase().includes(lowerSearch)
          )
          return filteredOptions.length > 0
        } else {
          // This is a regular option
          return item.text.toLowerCase().includes(lowerSearch)
        }
      }).map(item => {
        if (item.label) {
          // Filter the optgroup's options
          return {
            ...item,
            options: item.options.filter(opt =>
              opt.text.toLowerCase().includes(lowerSearch)
            )
          }
        }
        return item
      })

      resolve(filtered)
    })
  }

  showError(message) {
    if (this.slimselect) {
      this.slimselect.setData([
        {
          text: `⚠️ ${message}`,
          value: '',
          placeholder: true
        }
      ])
    }
  }

  // Public method to refresh tasks
  refresh() {
    this.loadTasks()
  }

  // Public method to get selected task data
  getSelectedTaskData() {
    const selected = this.slimselect.getSelected()
    if (selected && selected.length > 0 && selected[0]) {
      const option = this.slimselect.getData()
        .flatMap(item => item.options || [item])
        .find(opt => opt.value === selected[0])
      return option?.data || null
    }
    return null
  }
}