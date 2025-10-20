import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submit"]

  connect() {
    // MutationObserver instead of listening for turbo:frame-render because this event
    // is not bubbling up properly?
    this.observer = new MutationObserver(this.refresh)
    this.observer.observe(this.element, { subtree: true, childList: true })
    this.refresh()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  refresh = () => {
    if (!this.hasSubmitTarget) return
    this.submitTarget.disabled = this.checkboxTargets.every(cb => !cb.checked)
  }
}
