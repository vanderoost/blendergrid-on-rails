import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { path: String, interval: Number, isForced: Boolean }
  static targets = ["loadingProject"]

  connect() {
    if (this.isForcedValue) this.#startPolling()
    document.addEventListener("turbo:before-stream-render", this.#maybeStartPolling)
  }

  loadingProjectTargetConnected() {
    this.#maybeStartPolling()
  }

  disconnect() {
    this.#stopPolling()
    document.removeEventListener("turbo:before-stream-render", this.#maybeStartPolling)
  }

  #maybeStartPolling = () => {
    if (this.loadingProjectTargets.length == 0) return
    this.#startPolling()
  }

  #startPolling = () => {
    clearInterval(this.interval)
    this.interval = setInterval(this.#maybeReload, this.intervalValue)
  }

  #maybeStopPolling = () => {
    if (this.shouldStopPolling) {
      this.#stopPolling()
    }
  }

  #stopPolling = () => {
    clearInterval(this.interval)
  }

  #maybeReload = () => {
    if (this.shouldStopPolling) {
      this.#stopPolling()
      return
    }

    this.element.src = this.pathValue
    this.element.addEventListener("turbo:frame-render",
      this.#maybeStopPolling, { once: true }
    )
  }

  get shouldStopPolling() {
    return this.loadingProjectTargets.length == 0 && !this.isForcedValue
  }
}
