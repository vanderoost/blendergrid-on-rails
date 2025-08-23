import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "summary", "input"]

  connect() {
    console.log("UploadController connected")

    this.fileItemsByName = new Map()
    this.items = new Map()
    this.totalSize = 0
    this.uploadedSizes = new Map()
    this.smoothEta = null
    this.etaCalcDelay = 3000
  }

  showFiles() {
    const files = this.inputTarget.files
    console.debug("files:", files)

    for (var i = 0; i < files.length; i++) {
      const file = files[i]
      this.totalSize += file.size
      const wrapper = document.createElement("div")
      wrapper.dataset.progress = 0
      // TODO: Consider using a template
      wrapper.innerHTML = `
        <progress value="0" max="100" data-progress></progress>
        <span>${file.name}</span>
        <span>${humanFileSize(file.size)}</span>
      `
      this.listTarget.appendChild(wrapper)
      this.fileItemsByName.set(file.name, wrapper)
    }
  }

  uploadsStart() {
    this.startTime = Date.now()
  }

  uploadInit(event) {
    console.log("UploadController uploadInit - event:", event)
    const { file } = event.detail
    this.totalSize += file.size
  }

  uploadProgress(e) {
    const { id, file, progress } = e.detail
    this.uploadedSizes.set(id, Math.round(file.size * progress / 100))
    const item = this.fileItemsByName.get(file.name)
    if (item) item.querySelector("progress").value = progress

    this.trackTotalProgress()
  }

  trackTotalProgress() {
    const bytesDone = this.uploadedSizes.values().reduce((acc, n) => acc + n, 0)
    const percent = bytesDone / this.totalSize * 100

    const now = Date.now()
    const elapsed = now - this.startTime

    let progressMessage = `Uploading ${percent.toFixed(1)}%`

    if (elapsed > this.etaCalcDelay) {
      console.debug("calculating eta")
      const bytesRemaining = this.totalSize - bytesDone
      const eta = now + elapsed / bytesDone * bytesRemaining

      if (this.smoothEta === null) {
        this.smoothEta = eta
      } else {
        this.smoothEta = 0.99 * this.smoothEta + 0.01 * eta
      }
      const remaining = this.smoothEta - now
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

const humanFileSize = (bytes) => {
  const thresh = 1000
  const units = ["B", "kB", "MB", "GB", "TB", "PB"]

  let u = 0
  for (; u < units.length && Math.abs(bytes) >= thresh; u++) {
    bytes /= thresh
  }

  const decimals = Math.max(0, 1 - ~~Math.log10(bytes))
  return bytes.toFixed(decimals) + units[u]
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
