import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="timer"
export default class extends Controller {
  static targets = ["display", "startBtn", "stopBtn", "projectSelect", "description"]
  static values = {
    running: Boolean,
    startTime: String,
    entryId: Number
  }

  connect() {
    if (this.runningValue && this.startTimeValue) {
      this.startTimer()
    }
  }

  disconnect() {
    this.stopTimer()
  }

  start() {
    const projectId = this.projectSelectTarget.value
    if (!projectId) {
      alert("Please select a project")
      return
    }

    const description = this.hasDescriptionTarget ? this.descriptionTarget.value : ""

    fetch('/timer/start', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        project_id: projectId,
        description: description
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.runningValue = true
        this.startTimeValue = data.started_at
        this.entryIdValue = data.id
        this.startTimerDisplay()
      } else {
        alert(data.error || "Failed to start timer")
      }
    })
    .catch(error => {
      console.error('Error:', error)
      alert("Failed to start timer")
    })
  }

  stop() {
    if (!this.entryIdValue) return

    fetch(`/timer/stop/${this.entryIdValue}`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.runningValue = false
        this.stopTimerDisplay()
        // Reload the page to update recent entries
        window.location.reload()
      } else {
        alert(data.error || "Failed to stop timer")
      }
    })
    .catch(error => {
      console.error('Error:', error)
      alert("Failed to stop timer")
    })
  }

  startTimerDisplay() {
    this.updateDisplay()
    this.timer = setInterval(() => {
      this.updateDisplay()
    }, 1000)

    if (this.hasStartBtnTarget && this.hasStopBtnTarget) {
      this.startBtnTarget.classList.add('hidden')
      this.stopBtnTarget.classList.remove('hidden')
    }
  }

  stopTimerDisplay() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }

    if (this.hasDisplayTarget) {
      this.displayTarget.textContent = "00:00:00"
    }

    if (this.hasStartBtnTarget && this.hasStopBtnTarget) {
      this.startBtnTarget.classList.remove('hidden')
      this.stopBtnTarget.classList.add('hidden')
    }
  }

  updateDisplay() {
    if (!this.hasDisplayTarget || !this.startTimeValue) return

    const start = new Date(this.startTimeValue)
    const now = new Date()
    const diff = Math.floor((now - start) / 1000)

    const hours = Math.floor(diff / 3600).toString().padStart(2, '0')
    const minutes = Math.floor((diff % 3600) / 60).toString().padStart(2, '0')
    const seconds = (diff % 60).toString().padStart(2, '0')

    this.displayTarget.textContent = `${hours}:${minutes}:${seconds}`
  }

  // Private method alias for consistency
  stopTimer() {
    this.stopTimerDisplay()
  }

  startTimer() {
    this.startTimerDisplay()
  }
}