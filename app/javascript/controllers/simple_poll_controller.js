import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { path: String, interval: { type: Number, default: 20_000 } }
  static targets = ["inProgress"]

  connect() {
    if (this.hasInProgressTarget) {
      this.#startPolling()
    }
  }

  disconnect() {
    this.#stopPolling()
  }

  #startPolling = () => {
    this.element.src = this.pathValue
    this.interval = setInterval(this.#maybeReload, this.intervalValue)
  }

  #stopPolling = () => {
    clearInterval(this.interval)
  }

  #maybeReload = () => {
    if (!this.hasInProgressTarget) {
      this.#stopPolling()
      return
    }

    this.element.reload()
  }
}
