import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "backdrop", "panel"]

  connect() {
    this.handleEscape = this.handleEscape.bind(this)

    // Create handleUploadSuccess method if it doesn't exist
    if (!this.handleUploadSuccess) {
      this.handleUploadSuccess = () => {
        this.close()
      }
    }

    // Listen for successful upload events
    document.addEventListener("avatar:uploaded", this.handleUploadSuccess.bind(this))
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleEscape)
    document.removeEventListener("avatar:uploaded", this.handleUploadSuccess)
  }

  open(event) {
    event.preventDefault()

    // Show modal
    this.modalTarget.classList.remove("hidden")

    // Add event listeners
    document.addEventListener("keydown", this.handleEscape)

    // Focus management
    this.previouslyFocusedElement = document.activeElement

    // Animate in
    requestAnimationFrame(() => {
      this.backdropTarget.classList.remove("opacity-0")
      this.backdropTarget.classList.add("opacity-100")
      this.panelTarget.classList.remove("opacity-0", "translate-y-4", "sm:translate-y-0", "sm:scale-95")
      this.panelTarget.classList.add("opacity-100", "translate-y-0", "sm:scale-100")
    })

    // Prevent body scroll
    document.body.style.overflow = "hidden"
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }

    // Animate out
    this.backdropTarget.classList.remove("opacity-100")
    this.backdropTarget.classList.add("opacity-0")
    this.panelTarget.classList.remove("opacity-100", "translate-y-0", "sm:scale-100")
    this.panelTarget.classList.add("opacity-0", "translate-y-4", "sm:translate-y-0", "sm:scale-95")

    // Hide after animation
    setTimeout(() => {
      this.modalTarget.classList.add("hidden")

      // Restore focus
      if (this.previouslyFocusedElement) {
        this.previouslyFocusedElement.focus()
      }

      // Restore body scroll
      document.body.style.overflow = ""
    }, 200)

    // Remove event listeners
    document.removeEventListener("keydown", this.handleEscape)
  }

  handleBackdropClick(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}