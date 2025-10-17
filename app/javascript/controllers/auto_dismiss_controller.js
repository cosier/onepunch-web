import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="auto-dismiss"
export default class extends Controller {
  static values = { delay: Number }

  connect() {
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, this.delayValue || 5000)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    this.element.remove()
  }
}