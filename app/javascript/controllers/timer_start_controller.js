import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  handleSubmit(event) {
    // Get the form and button
    const form = event.target
    const button = form.querySelector('button[type="submit"]')

    // Disable button and show loading state
    if (button) {
      button.disabled = true
      button.classList.add('opacity-75', 'cursor-not-allowed')

      // Store original content
      const originalContent = button.innerHTML

      // Add loading spinner
      button.innerHTML = `
        <svg class="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <span class="ml-2">Starting...</span>
      `

      // Re-enable after response (Turbo will handle the actual update)
      setTimeout(() => {
        if (button.disabled) {
          button.disabled = false
          button.classList.remove('opacity-75', 'cursor-not-allowed')
          button.innerHTML = originalContent
        }
      }, 3000)
    }
  }
}