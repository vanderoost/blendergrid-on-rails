import { Controller } from "@hotwired/stimulus"

// Add this to a form to make it auto-submit with debounce

export default class extends Controller {
  connect() {
    this.element.addEventListener("input", this.debounceSubmit.bind(this))
  }

  debounceSubmit(event) {
    clearTimeout(this.timeout)
    const debounce = ["checkbox", "radio", "select-one"].includes(event.target.type) ? 0 : 300
    this.timeout = setTimeout(() => { this.element.requestSubmit() }, debounce)
  }
}
