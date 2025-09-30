import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit(event) {
    // Small delay to ensure the value is updated
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 500)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}