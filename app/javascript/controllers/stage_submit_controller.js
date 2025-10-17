import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submit"]

  connect() {
    this.observer = new MutationObserver(() => this.refresh())
    this.observer.observe(this.element, { childList: true, subtree: true })
    this.refresh()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  refresh() {
    if (!this.hasSubmitTarget) return
    this.submitTarget.disabled = this.checkboxTargets.every(cb => !cb.checked)
  }
}
