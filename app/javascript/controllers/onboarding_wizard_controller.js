import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "step", "stepIndicator", "nextButton", "previousButton", "skipButton"]

  connect() {
    this.currentStep = 1
    this.totalSteps = 5
    this.updateUI()
  }

  next(event) {
    event.preventDefault()

    if (this.currentStep === this.totalSteps) {
      // Submit the form on the last step
      this.formTarget.requestSubmit()
    } else {
      this.currentStep++
      this.updateUI()
    }
  }

  previous(event) {
    event.preventDefault()

    if (this.currentStep > 1) {
      this.currentStep--
      this.updateUI()
    }
  }

  skip(event) {
    event.preventDefault()

    if (this.currentStep === this.totalSteps) {
      // Go to dashboard
      window.location.href = '/dashboard'
    } else {
      this.currentStep++
      this.updateUI()
    }
  }

  submit(event) {
    // Let the form submit naturally on the last step
    if (this.currentStep !== this.totalSteps) {
      event.preventDefault()
    }
  }

  updateUI() {
    // Update step visibility
    this.stepTargets.forEach(step => {
      const stepNumber = parseInt(step.dataset.step)
      if (stepNumber === this.currentStep) {
        step.classList.remove("hidden")
      } else {
        step.classList.add("hidden")
      }
    })

    // Update progress indicators
    this.stepIndicatorTargets.forEach(indicator => {
      const stepNumber = parseInt(indicator.dataset.step)
      if (stepNumber <= this.currentStep) {
        indicator.classList.remove("bg-gray-200", "text-gray-600")
        indicator.classList.add("bg-indigo-600", "text-white")
      } else {
        indicator.classList.remove("bg-indigo-600", "text-white")
        indicator.classList.add("bg-gray-200", "text-gray-600")
      }
    })

    // Update button visibility and text
    if (this.currentStep === 1) {
      this.previousButtonTarget.classList.add("hidden")
    } else {
      this.previousButtonTarget.classList.remove("hidden")
    }

    if (this.currentStep === this.totalSteps) {
      this.nextButtonTarget.textContent = "Complete Setup"
      this.skipButtonTarget.textContent = "Go to Dashboard"
    } else {
      this.nextButtonTarget.textContent = "Next"
      this.skipButtonTarget.textContent = "Skip this step"
    }
  }
}