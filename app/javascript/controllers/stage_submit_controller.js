import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submit"]

  connect() {
    this.refresh()
  }

  refresh() {
    this.submitTarget.disabled = this.checkboxTargets.every(cb => !cb.checked)
  }
}
