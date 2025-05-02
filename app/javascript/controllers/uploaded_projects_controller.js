import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "button"]

  connect = () => this.updateButton()

  checkboxTargetConnected = () => this.updateForm()
  checkboxTargetDisconnected = () => this.updateForm()

  updateForm = () => {
    this.updateButton()

    if (this.checkboxTargets.length < 2) {
      this.checkboxTargets.forEach(checkbox => checkbox.classList.add("collapse"))
    } else {
      this.checkboxTargets.forEach(checkbox => checkbox.classList.remove("collapse"))
    }
  }

  updateButton = () => { this.buttonTarget.disabled = !this.formIsValid }

  get formIsValid() {
    return this.checkboxTargets.filter(checkbox => checkbox.checked).length > 0
  }
}
