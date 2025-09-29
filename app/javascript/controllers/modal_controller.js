import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["container", "backdrop", "panel", "title", "message", "confirmBtn", "cancelBtn"]
  static values = {
    open: Boolean,
    action: String,
    url: String,
    method: String,
    confirmText: String,
    cancelText: String,
    confirmClass: String
  }

  connect() {
    // Close on escape key
    this.handleEscape = this.handleEscape.bind(this)
    this.handleBackdropClick = this.handleBackdropClick.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleEscape)
  }

  open(event) {
    event.preventDefault()

    // Get data from the triggering element
    const button = event.currentTarget
    this.urlValue = button.dataset.modalUrl || ""
    this.methodValue = button.dataset.modalMethod || "POST"
    this.confirmTextValue = button.dataset.modalConfirmText || "Confirm"
    this.cancelTextValue = button.dataset.modalCancelText || "Cancel"
    this.confirmClassValue = button.dataset.modalConfirmClass || "bg-red-600 hover:bg-red-700"

    // Set modal content
    if (button.dataset.modalTitle) {
      this.titleTarget.textContent = button.dataset.modalTitle
    }
    if (button.dataset.modalMessage) {
      this.messageTarget.textContent = button.dataset.modalMessage
    }

    // Update button text and styling
    this.confirmBtnTarget.textContent = this.confirmTextValue
    this.confirmBtnTarget.className = `inline-flex justify-center w-full rounded-md border border-transparent px-4 py-2 text-base font-medium text-white shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 sm:ml-3 sm:w-auto sm:text-sm ${this.confirmClassValue} focus:ring-red-500`
    this.cancelBtnTarget.textContent = this.cancelTextValue

    // Show modal
    this.openValue = true
    if (this.hasContainerTarget) {
      this.containerTarget.classList.remove("hidden")
    }

    // Add event listeners
    document.addEventListener("keydown", this.handleEscape)

    // Focus management
    this.previouslyFocusedElement = document.activeElement
    this.cancelBtnTarget.focus()

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
      if (this.hasContainerTarget) {
        this.containerTarget.classList.add("hidden")
      }
      this.openValue = false

      // Restore focus
      if (this.previouslyFocusedElement) {
        this.previouslyFocusedElement.focus()
      }
    }, 200)

    // Remove event listeners
    document.removeEventListener("keydown", this.handleEscape)
  }

  confirm() {
    if (!this.urlValue) {
      console.error("No URL specified for modal action")
      return
    }

    // Disable buttons during request
    this.confirmBtnTarget.disabled = true
    this.cancelBtnTarget.disabled = true
    this.confirmBtnTarget.textContent = "Processing..."

    // Create form and submit
    const form = document.createElement("form")
    form.method = "POST"
    form.action = this.urlValue
    form.style.display = "none"

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    const csrfInput = document.createElement("input")
    csrfInput.type = "hidden"
    csrfInput.name = "authenticity_token"
    csrfInput.value = csrfToken
    form.appendChild(csrfInput)

    // Add method override for DELETE
    if (this.methodValue === "DELETE") {
      const methodInput = document.createElement("input")
      methodInput.type = "hidden"
      methodInput.name = "_method"
      methodInput.value = "DELETE"
      form.appendChild(methodInput)
    }

    // Add Turbo configuration
    form.dataset.turbo = "true"

    document.body.appendChild(form)
    form.requestSubmit()

    // Close modal
    this.close()
  }

  cancel() {
    this.close()
  }

  handleEscape(event) {
    if (event.key === "Escape" && this.openValue) {
      this.close()
    }
  }

  handleBackdropClick(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  openValueChanged() {
    if (this.openValue) {
      document.body.style.overflow = "hidden"
    } else {
      document.body.style.overflow = ""
    }
  }
}