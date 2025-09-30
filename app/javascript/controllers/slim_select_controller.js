import { Controller } from "@hotwired/stimulus"
import SlimSelect from "slim-select"

// Reusable SlimSelect controller for enhanced multi-select dropdowns
export default class extends Controller {
  static targets = ["select"]
  static values = {
    placeholder: String,
    allowDeselect: { type: Boolean, default: true },
    closeOnSelect: { type: Boolean, default: false },
    searchText: { type: String, default: "Search..." },
    searchPlaceholder: { type: String, default: "Search" }
  }

  connect() {
    this.initializeSlimSelect()
  }

  disconnect() {
    if (this.slimselect) {
      this.slimselect.destroy()
    }
  }

  initializeSlimSelect() {
    const selectElement = this.hasSelectTarget ? this.selectTarget : this.element

    this.slimselect = new SlimSelect({
      select: selectElement,
      settings: {
        placeholderText: this.placeholderValue || "Select...",
        allowDeselect: this.allowDeselectValue,
        closeOnSelect: this.closeOnSelectValue,
        searchText: this.searchTextValue,
        searchPlaceholder: this.searchPlaceholderValue,
        searchHighlight: true
      },
      events: {
        afterChange: (newVal) => {
          // Dispatch custom event for parent controllers to listen to
          this.dispatch("change", { detail: { values: newVal } })

          // Trigger native change event for form submissions
          const event = new Event('change', { bubbles: true })
          selectElement.dispatchEvent(event)
        }
      }
    })
  }

  // Public method to update options programmatically
  setData(data) {
    if (this.slimselect) {
      this.slimselect.setData(data)
    }
  }

  // Public method to get selected values
  getSelected() {
    return this.slimselect ? this.slimselect.getSelected() : []
  }

  // Public method to set selected values
  setSelected(values) {
    if (this.slimselect) {
      this.slimselect.setSelected(values)
    }
  }
}