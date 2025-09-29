import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "search", "item"]

  connect() {
    // Close on outside click
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)

    // Keyboard shortcuts
    this.handleKeyboard = this.handleKeyboard.bind(this)
    document.addEventListener("keydown", this.handleKeyboard)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeyboard)
    document.removeEventListener("click", this.closeOnOutsideClick)
  }

  toggle(event) {
    event.stopPropagation()

    if (this.dropdownTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.dropdownTarget.classList.remove("hidden")
    document.addEventListener("click", this.closeOnOutsideClick)

    // Focus search if it exists
    if (this.hasSearchTarget) {
      this.searchTarget.focus()
    }

    // Animate in
    requestAnimationFrame(() => {
      this.dropdownTarget.classList.add("opacity-100", "transform", "scale-100")
    })
  }

  close() {
    this.dropdownTarget.classList.add("hidden")
    document.removeEventListener("click", this.closeOnOutsideClick)

    // Reset search
    if (this.hasSearchTarget) {
      this.searchTarget.value = ""
      this.filter()
    }
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  filter() {
    if (!this.hasSearchTarget || !this.hasItemTarget) return

    const query = this.searchTarget.value.toLowerCase()

    this.itemTargets.forEach(item => {
      const name = item.dataset.organizationName
      if (name && name.includes(query)) {
        item.classList.remove("hidden")
      } else {
        item.classList.add("hidden")
      }
    })
  }

  handleKeyboard(event) {
    // Cmd/Ctrl + K to open switcher
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      this.open()
    }

    // Escape to close
    if (event.key === "Escape" && !this.dropdownTarget.classList.contains("hidden")) {
      this.close()
    }
  }
}
