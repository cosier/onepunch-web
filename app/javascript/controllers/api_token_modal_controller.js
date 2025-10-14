import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="api-token-modal"
export default class extends Controller {
  static targets = ["modal", "backdrop", "panel", "tokenValue", "copyButtonText"]

  connect() {
    this.handleEscape = this.handleEscape.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleEscape)
  }

  openNew(event) {
    event.preventDefault()

    // Load the new token form via Turbo Frame
    const frame = document.getElementById("api_token_modal")
    frame.src = "/settings/api_tokens/new"

    this.open()
  }

  open() {
    // Show modal
    this.modalTarget.classList.remove("hidden")

    // Add event listeners
    document.addEventListener("keydown", this.handleEscape)

    // Prevent body scroll
    document.body.style.overflow = "hidden"

    // Animate in
    requestAnimationFrame(() => {
      this.backdropTarget.classList.remove("opacity-0")
      this.backdropTarget.classList.add("opacity-100")
      this.panelTarget.classList.remove("opacity-0", "translate-y-4", "sm:translate-y-0", "sm:scale-95")
      this.panelTarget.classList.add("opacity-100", "translate-y-0", "sm:scale-100")
    })
  }

  close() {
    // Animate out
    this.backdropTarget.classList.remove("opacity-100")
    this.backdropTarget.classList.add("opacity-0")
    this.panelTarget.classList.remove("opacity-100", "translate-y-0", "sm:scale-100")
    this.panelTarget.classList.add("opacity-0", "translate-y-4", "sm:translate-y-0", "sm:scale-95")

    // Hide after animation
    setTimeout(() => {
      this.modalTarget.classList.add("hidden")
      document.body.style.overflow = ""

      // Clear the turbo frame
      const frame = document.getElementById("api_token_modal")
      frame.innerHTML = ""
    }, 200)

    // Remove event listeners
    document.removeEventListener("keydown", this.handleEscape)
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  handleBackdropClick(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  copyToken(event) {
    event.preventDefault()

    if (this.hasTokenValueTarget) {
      const token = this.tokenValueTarget.value

      // Copy to clipboard
      navigator.clipboard.writeText(token).then(() => {
        // Update button text
        if (this.hasCopyButtonTextTarget) {
          const originalText = this.copyButtonTextTarget.textContent
          this.copyButtonTextTarget.textContent = "Copied!"

          // Reset after 2 seconds
          setTimeout(() => {
            this.copyButtonTextTarget.textContent = originalText
          }, 2000)
        }
      }).catch(err => {
        console.error("Failed to copy token:", err)
      })
    }
  }
}
