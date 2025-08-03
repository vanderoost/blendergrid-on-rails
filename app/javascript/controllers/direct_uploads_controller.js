import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "summary"]

  connect() {
    this.items = new Map()
    this.totalSize = 0
    this.uploadedSizes = new Map()
    this.smoothEta = null
    this.etaCalcDelay = 3000
  }

  uploadsStart() {
    this.startTime = Date.now()
  }

  uploadInit(e) {
    const { id, file } = e.detail
    this.totalSize += file.size
    const wrapper = document.createElement("div")
    wrapper.className = "upload-progress"
    wrapper.dataset.uploadId = id
    wrapper.innerHTML = `
      <progress value="0" max="100" data-progress></progress>
      <span>${file.name}</span>
    `
    this.listTarget.appendChild(wrapper)
    this.items.set(id, wrapper)
  }

  uploadProgress(e) {
    const { file, id, progress } = e.detail
    this.uploadedSizes.set(id, Math.round(file.size * progress / 100))
    const el = this.items.get(id)
    if (el) el.querySelector("[data-progress]").value = progress

    this.trackTotalProgress()
  }

  trackTotalProgress() {
    const bytesDone = this.uploadedSizes.values().reduce((acc, n) => acc + n, 0)
    const percent = bytesDone / this.totalSize * 100

    const now = Date.now()
    const elapsed = now - this.startTime

    let progressMessage = `Uploading ${percent.toFixed(1)}%`

    if (elapsed > this.etaCalcDelay) {
      const bytesRemaining = this.totalSize - bytesDone
      const eta = now + elapsed / bytesDone * bytesRemaining

      if (this.smoothEta === null) {
        this.smoothEta = eta
      } else {
        this.smoothEta = 0.99 * this.smoothEta + 0.01 * eta
      }
      const remaining = this.smoothEta - Date.now()
      progressMessage += ` - ${humanDuration(remaining)} remaining`
    }

    this.summaryTarget.innerHTML = progressMessage
  }

  uploadError(e) {
    const { id, error } = e.detail
    const el = this.items.get(id)
    if (el) {
      el.insertAdjacentText("beforeend", ` — failed: ${error}`)
      el.querySelector("[data-progress]")?.remove()
      this.items.delete(id)
    }
  }

  uploadEnd(e) {
    const { id } = e.detail
    const el = this.items.get(id)
    if (el) {
      const bar = el.querySelector("[data-progress]")
      if (bar) bar.value = 100
      this.items.delete(id)
    }
  }
}

function humanDuration(ms) {
  let seconds = Math.ceil(ms / 1000)
  let minutes = Math.floor(seconds / 60)
  let hours = Math.floor(minutes / 60)
  let days = Math.floor(hours / 24)

  if (days > 1) {
    return `${days} days`
  }

  if (hours > 1) {
    return `${hours} hours`
  }

  if (minutes > 1) {
    return `${minutes} minutes`
  }

  if (seconds > 1) {
    return `${seconds} seconds`
  }

  return "1 second"
}
