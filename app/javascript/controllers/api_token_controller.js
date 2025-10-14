import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="api-token"
export default class extends Controller {
  copyMaskedToken(event) {
    event.preventDefault()

    const maskedToken = event.currentTarget.dataset.apiTokenMaskedValue

    if (maskedToken) {
      // Copy to clipboard
      navigator.clipboard.writeText(maskedToken).then(() => {
        // Show temporary success feedback
        const button = event.currentTarget
        const originalHTML = button.innerHTML

        button.innerHTML = `
          <span class="inline-flex items-center gap-1">
            ${maskedToken}
            <svg class="h-3 w-3 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
          </span>
        `

        button.classList.add("text-green-600")

        // Reset after 2 seconds
        setTimeout(() => {
          button.innerHTML = originalHTML
          button.classList.remove("text-green-600")
        }, 2000)
      }).catch(err => {
        console.error("Failed to copy masked token:", err)
      })
    }
  }
}
