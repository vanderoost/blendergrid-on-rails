import { Controller } from "@hotwired/stimulus"

// Add this to a form to make it auto-submit with debounce
export default class extends Controller {
  connect() {
    console.debug("Autosubmit connected")
    this.element.addEventListener("input", this.debounceSubmit.bind(this))
  }

  debounceSubmit(event) {
    console.debug("Autosubmit with:", event.target.type)
    clearTimeout(this.timeout)

    const debounce = ["checkbox", "radio", "select-one"].includes(event.target.type) ? 0 : 2000
    this.timeout = setTimeout(() => { this.element.requestSubmit() }, debounce)
  }
}
