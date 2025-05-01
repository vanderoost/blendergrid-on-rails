import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "button"]

  connect() {
    console.debug("Uploaded Projects Controller")
    this.validateForm()
  }

  update() {
    this.validateForm()
  }

  validateForm() {
    console.debug("valid?", this.formIsValid)
    this.buttonTarget.disabled = !this.formIsValid
  }

  get formIsValid() {
    return !!this.checkboxTargets.filter(checkbox => checkbox.checked).length
  }
}
