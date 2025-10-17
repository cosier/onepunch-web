import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="time-entry-card"
export default class extends Controller {
  static values = { id: Number }

  connect() {
    // Add any initialization if needed
  }

  // Handle optimistic UI updates for delete
  markDeleting() {
    this.element.style.opacity = "0.5"
    this.element.style.pointerEvents = "none"
  }

  // Handle optimistic UI updates for stop
  markStopping() {
    const runningBadge = this.element.querySelector('[data-running-badge]')
    if (runningBadge) {
      runningBadge.textContent = "Stopping..."
      runningBadge.classList.remove("bg-blue-100", "text-blue-800")
      runningBadge.classList.add("bg-yellow-100", "text-yellow-800")
    }
  }

  // Restore UI if action fails
  restore() {
    this.element.style.opacity = "1"
    this.element.style.pointerEvents = "auto"
  }
}