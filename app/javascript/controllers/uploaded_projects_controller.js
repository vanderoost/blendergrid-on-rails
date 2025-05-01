import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "button"]

  connect = () => this.updateButton()
  checkboxTargetConnected = () => this.updateButton()
  checkboxTargetDisconnected = () => this.updateButton()

  updateButton = () => { this.buttonTarget.disabled = !this.formIsValid }

  get formIsValid() {
    return this.checkboxTargets.filter(checkbox => checkbox.checked).length > 0
  }
}
