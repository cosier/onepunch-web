import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    // Show the first tab by default
    this.showTab(0)
  }

  switch(event) {
    const tabIndex = this.tabTargets.indexOf(event.currentTarget)
    this.showTab(tabIndex)
  }

  showTab(index) {
    // Update tab styles
    this.tabTargets.forEach((tab, i) => {
      if (i === index) {
        tab.classList.remove("border-transparent", "text-gray-500", "hover:text-gray-700", "hover:border-gray-300")
        tab.classList.add("border-indigo-500", "text-indigo-600")
      } else {
        tab.classList.add("border-transparent", "text-gray-500", "hover:text-gray-700", "hover:border-gray-300")
        tab.classList.remove("border-indigo-500", "text-indigo-600")
      }
    })

    // Show/hide panels
    this.panelTargets.forEach((panel, i) => {
      if (i === index) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}