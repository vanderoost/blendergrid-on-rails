import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submit"]

  connect() {
    // MutationObserver instead of listening for turbo:frame-render because this event
    // is not bubbling up properly?
    this.observer = new MutationObserver(this.update)
    this.observer.observe(this.element, { subtree: true, childList: true })
    this.update()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  update = () => {
    if (!this.hasSubmitTarget) return
    this.submitTarget.disabled = this.checkboxTargets.every(cb => !cb.checked)
  }
}
