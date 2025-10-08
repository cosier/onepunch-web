import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "placeholder", "filename", "form"]
  static values = {
    maxSize: { type: Number, default: 5242880 }, // 5MB default
    acceptedFormats: { type: Array, default: ["image/jpeg", "image/png", "image/gif", "image/webp"] }
  }

  connect() {
    this.element.addEventListener("dragover", this.handleDragOver.bind(this))
    this.element.addEventListener("drop", this.handleDrop.bind(this))
    this.element.addEventListener("dragleave", this.handleDragLeave.bind(this))
    this.element.addEventListener("dragenter", this.handleDragEnter.bind(this))
  }

  handleDragOver(e) {
    e.preventDefault()
    e.stopPropagation()
    this.element.classList.add("border-indigo-500", "bg-indigo-50")
  }

  handleDragEnter(e) {
    e.preventDefault()
    e.stopPropagation()
    this.element.classList.add("border-indigo-500", "bg-indigo-50")
  }

  handleDragLeave(e) {
    e.preventDefault()
    e.stopPropagation()
    if (!this.element.contains(e.relatedTarget)) {
      this.element.classList.remove("border-indigo-500", "bg-indigo-50")
    }
  }

  handleDrop(e) {
    e.preventDefault()
    e.stopPropagation()
    this.element.classList.remove("border-indigo-500", "bg-indigo-50")

    const files = e.dataTransfer.files
    if (files.length > 0) {
      this.handleFile(files[0])
    }
  }

  handleClick(e) {
    e.preventDefault()
    this.inputTarget.click()
  }

  handleFileSelect(e) {
    const files = e.target.files
    if (files.length > 0) {
      this.handleFile(files[0])
    }
  }

  handleFile(file) {
    // Validate file type
    if (!this.acceptedFormatsValue.includes(file.type)) {
      this.showError(`Please upload a valid image file (JPEG, PNG, GIF, or WebP)`)
      return
    }

    // Validate file size
    if (file.size > this.maxSizeValue) {
      const maxSizeMB = this.maxSizeValue / 1024 / 1024
      this.showError(`File size must be less than ${maxSizeMB}MB`)
      return
    }

    // Preview the image
    const reader = new FileReader()
    reader.onload = (e) => {
      if (this.hasPreviewTarget) {
        this.previewTarget.src = e.target.result
        this.previewTarget.classList.remove("hidden")
      }
      if (this.hasPlaceholderTarget) {
        this.placeholderTarget.classList.add("hidden")
      }
      if (this.hasFilenameTarget) {
        this.filenameTarget.textContent = file.name
        this.filenameTarget.classList.remove("hidden")
      }
    }
    reader.readAsDataURL(file)

    // Create a new FileList with the file
    const dataTransfer = new DataTransfer()
    dataTransfer.items.add(file)
    this.inputTarget.files = dataTransfer.files

    // Auto-submit if form target exists
    if (this.hasFormTarget) {
      // Small delay to ensure preview is shown
      setTimeout(() => {
        this.formTarget.requestSubmit()
      }, 100)
    }
  }

  removeFile(e) {
    e.preventDefault()
    e.stopPropagation()

    // Clear the input
    this.inputTarget.value = ""

    // Reset preview
    if (this.hasPreviewTarget) {
      this.previewTarget.src = ""
      this.previewTarget.classList.add("hidden")
    }
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.classList.remove("hidden")
    }
    if (this.hasFilenameTarget) {
      this.filenameTarget.textContent = ""
      this.filenameTarget.classList.add("hidden")
    }
  }

  showError(message) {
    // Create or update error message
    let errorElement = this.element.querySelector('[data-dropzone-error]')
    if (!errorElement) {
      errorElement = document.createElement('div')
      errorElement.setAttribute('data-dropzone-error', '')
      errorElement.className = 'mt-2 text-sm text-red-600'
      this.element.appendChild(errorElement)
    }
    errorElement.textContent = message

    // Remove error after 5 seconds
    setTimeout(() => {
      errorElement.remove()
    }, 5000)
  }
}