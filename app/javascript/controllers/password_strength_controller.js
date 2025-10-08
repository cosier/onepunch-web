import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "password",
    "confirmation",
    "strengthBar",
    "strengthText",
    "lengthRequirement",
    "uppercaseRequirement",
    "lowercaseRequirement",
    "numberRequirement",
    "specialRequirement",
    "matchRequirement",
    "submitButton",
    "toggleButton",
    "toggleIcon"
  ]

  connect() {
    this.checkStrength()
  }

  checkStrength() {
    const password = this.passwordTarget.value
    const confirmation = this.hasConfirmationTarget ? this.confirmationTarget.value : ""

    // Calculate strength score
    let score = 0
    const checks = {
      length: password.length >= 8,
      uppercase: /[A-Z]/.test(password),
      lowercase: /[a-z]/.test(password),
      number: /\d/.test(password),
      special: /[@$!%*?&#^()_+=\-{}[\]:;"'<>,.?/|\\~`]/.test(password)
    }

    // Update requirement indicators
    this.updateRequirement(this.lengthRequirementTarget, checks.length)
    this.updateRequirement(this.uppercaseRequirementTarget, checks.uppercase)
    this.updateRequirement(this.lowercaseRequirementTarget, checks.lowercase)
    this.updateRequirement(this.numberRequirementTarget, checks.number)
    this.updateRequirement(this.specialRequirementTarget, checks.special)

    // Check password match
    const passwordsMatch = password.length > 0 && password === confirmation
    if (this.hasMatchRequirementTarget) {
      this.updateRequirement(this.matchRequirementTarget, passwordsMatch || confirmation.length === 0)
    }

    // Calculate score
    Object.values(checks).forEach(passed => {
      if (passed) score++
    })

    // Additional points for length
    if (password.length >= 12) score++
    if (password.length >= 16) score++

    // Determine strength level
    let strength = "None"
    let strengthClass = "bg-gray-200"
    let strengthWidth = "0%"
    let textColor = "text-gray-500"

    if (password.length > 0) {
      if (score <= 2) {
        strength = "Weak"
        strengthClass = "bg-red-500"
        strengthWidth = "25%"
        textColor = "text-red-600"
      } else if (score <= 3) {
        strength = "Fair"
        strengthClass = "bg-orange-500"
        strengthWidth = "50%"
        textColor = "text-orange-600"
      } else if (score <= 5) {
        strength = "Good"
        strengthClass = "bg-yellow-500"
        strengthWidth = "75%"
        textColor = "text-yellow-600"
      } else {
        strength = "Strong"
        strengthClass = "bg-green-500"
        strengthWidth = "100%"
        textColor = "text-green-600"
      }
    }

    // Update UI
    this.strengthBarTarget.className = `h-full rounded-full transition-all duration-300 ${strengthClass}`
    this.strengthBarTarget.style.width = strengthWidth
    this.strengthTextTarget.textContent = strength
    this.strengthTextTarget.className = `text-sm font-medium ${textColor}`

    // Enable/disable submit button
    const canSubmit = checks.length && checks.uppercase && checks.lowercase &&
                      checks.number && (confirmation.length === 0 || passwordsMatch)

    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = !canSubmit
      if (canSubmit) {
        this.submitButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")
        this.submitButtonTarget.classList.add("hover:bg-indigo-700")
      } else {
        this.submitButtonTarget.classList.add("opacity-50", "cursor-not-allowed")
        this.submitButtonTarget.classList.remove("hover:bg-indigo-700")
      }
    }
  }

  checkMatch() {
    const password = this.passwordTarget.value
    const confirmation = this.confirmationTarget.value

    if (confirmation.length > 0) {
      const match = password === confirmation
      this.updateRequirement(this.matchRequirementTarget, match)

      // Update submit button state
      this.checkStrength()
    }
  }

  toggleVisibility(event) {
    event.preventDefault()

    const type = this.passwordTarget.type === "password" ? "text" : "password"
    this.passwordTarget.type = type

    if (this.hasConfirmationTarget) {
      this.confirmationTarget.type = type
    }

    // Update icon
    if (this.hasToggleIconTarget) {
      if (type === "text") {
        this.toggleIconTarget.innerHTML = `
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
        `
      } else {
        this.toggleIconTarget.innerHTML = `
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
        `
      }
    }
  }

  updateRequirement(element, passed) {
    if (passed) {
      element.classList.remove("text-gray-400")
      element.classList.add("text-green-600")
      const icon = element.querySelector("svg")
      if (icon) {
        icon.classList.remove("text-gray-300")
        icon.classList.add("text-green-500")
        icon.innerHTML = `
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        `
      }
    } else {
      element.classList.remove("text-green-600")
      element.classList.add("text-gray-400")
      const icon = element.querySelector("svg")
      if (icon) {
        icon.classList.remove("text-green-500")
        icon.classList.add("text-gray-300")
        icon.innerHTML = `
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" />
        `
      }
    }
  }
}