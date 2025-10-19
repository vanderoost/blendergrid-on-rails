import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  connect() {
    this.element.addEventListener("input", this.markAsDirty)
    this.element.addEventListener("change", this.debounceSubmit)
    document.addEventListener("turbo:before-visit", this.submitBeforeVisit)
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this.submitBeforeVisit)
  }

  markAsDirty = () => this.isDirty = true

  debounceSubmit = () => {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(this.#submit, 200)
  }

  submitBeforeVisit = event => {
    if (!this.isDirty) return

    event.preventDefault()

    this.element.addEventListener("turbo:submit-end", () => {
      Turbo.visit(event.detail.url)
    }, { once: true })

    clearTimeout(this.timeout)
    this.#submit()
  }

  #submit = () => {
    this.element.requestSubmit()
    this.isDirty = false
  }
}
