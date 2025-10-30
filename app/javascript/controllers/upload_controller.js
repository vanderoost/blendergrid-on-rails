import { Controller } from "@hotwired/stimulus"

const states = {
  empty: "empty",
  ready: "ready",
  uploading: "uploading",
  done: "done",
}
export default class extends Controller {
  static targets = ["input", "list", "submit", "summary",]
  static values = { status: String }

  connect() {
    this.fileItemsByName = new Map()
    this.items = new Map()
    this.totalSize = 0
    this.uploadedSizes = new Map()
    this.smoothEta = null
    this.etaCalcDelay = 3000
    this.startTime = 0
  }

  // Called on file input change
  // Should just care about presentation, don't keep track of total file size here
  showFiles() {
    if (this.statusValue === states.uploading) { return }
    const files = this.inputTarget.files

    this.listTarget.innerHTML = ""
    for (var i = 0; i < files.length; i++) {
      const file = files[i]
      const [filenameHead, filenameTail] = splitFilename(file.name)
      const fileElement = document.createElement("div")
      fileElement.className = "flex items-center justify-between gap-x-3 p-3 text-sm"
      fileElement.innerHTML = `
        <div class="relative w-5 h-5 flex-none">
          <svg class="w-full h-full" viewBox="0 0 64 64">
            <circle
              class="text-gray-300 dark:text-white/10 stroke-current"
              stroke-width="14"
              cx="32"
              cy="32"
              r="24"
              fill="transparent"
            ></circle>
            <circle
              class="text-primary-600 dark:text-primary-500 stroke-current progress_donut"
              stroke-width="14"
              cx="32"
              cy="32"
              r="24"
              fill="transparent"
              stroke-dasharray="150.8"
              stroke-dashoffset="150.8"
            ></circle>
          </svg>
        </div>
        <div class="flex grow min-w-0">
          <span class="truncate">${filenameHead}</span>
          <span class="whitespace-pre">${filenameTail}</span>
        </div>
        <div class="text-gray-500 dark:text-gray-400">${humanFileSize(file.size)}</div>
      `
      this.listTarget.appendChild(fileElement)
      this.fileItemsByName.set(file.name, fileElement)
    }

    if (files.length > 0) {
      this.statusValue = states.ready
      this.listTarget.classList.remove("hidden")
      this.submitTarget.disabled = false
      this.submitTarget.value = `Upload ${pluralize(files.length, "File")}`
    } else {
      this.submitTarget.disabled = true
      this.submitTarget.value = "Upload Files"
    }

  }

  uploadsStart() {
    if (this.statusValue !== states.uploading) {
      this.statusValue = states.uploading
      this.submitTarget.disabled = true
      this.submitTarget.value = `Uploading ${pluralize(this.inputTarget.files.length, "File")}`
    }

    if (this.startTime === 0) {
      this.startTime = Date.now()
    }
  }

  // Called on: direct-upload:initialize
  uploadInit(event) {
    const { file } = event.detail
    this.totalSize += file.size
  }

  uploadProgress(e) {
    const { id, file, progress } = e.detail // TODO: Let the Rails fork pass bytes
    const bytes = Math.round(file.size * progress / 100)
    this.uploadedSizes.set(id, bytes)

    // TODO: Make a donut controller for this?
    const item = this.fileItemsByName.get(file.name)
    if (item) {
      const donutLength = 150.8 * (1.0 - progress / 100.0)
      item.querySelector(".progress_donut").setAttribute("stroke-dashoffset", donutLength.toFixed(2))
    }

    this.trackTotalProgress()
  }

  trackTotalProgress() {
    const bytesDone = this.uploadedSizes.values().reduce((acc, n) => acc + n, 0)
    const percent = bytesDone / this.totalSize * 100

    this.summaryTarget.querySelector(".percentage").innerHTML = `Uploading: ${percent.toFixed(1)}%`
    this.summaryTarget.querySelector(".upload_progress").style.width = `${percent.toFixed(1)}%`

    const now = Date.now()
    const elapsed = now - this.startTime

    if (elapsed > this.etaCalcDelay) {
      const bytesRemaining = this.totalSize - bytesDone
      const eta = now + elapsed / bytesDone * bytesRemaining

      if (this.smoothEta === null) {
        this.smoothEta = eta
      } else {
        this.smoothEta = 0.99 * this.smoothEta + 0.01 * eta
      }
      const remaining = this.smoothEta - now
      this.summaryTarget.querySelector(".eta").innerHTML = `About ${humanDuration(remaining)} remaining`
    }

    if (this.summaryTarget.classList.contains("hidden")) {
      this.summaryTarget.classList.remove("hidden")
      this.summaryTarget.classList.add("flex")
    }
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
  seconds = seconds % 60

  let hours = Math.floor(minutes / 60)
  minutes = minutes % 60

  let days = Math.floor(hours / 24)
  hours = hours % 24

  if (days > 1) { return `${days} days` }
  if (hours > 9) { return `${hours} hours` }
  if (hours > 0) { return `${hours}:${String(minutes).padStart(2, '0')} h` }
  if (minutes > 4) { return `${minutes} minutes` }
  if (minutes > 0) { return `${minutes}:${String(seconds).padStart(2, '0')} m` }
  if (seconds > 1) { return `${seconds} seconds` }
  return "1 second"
}

function splitFilename(filename, tailLength = 10) {
  if (filename.length <= tailLength) {
    return ['', filename];
  }

  let firstPart = filename.slice(0, -tailLength);
  let lastPart = filename.slice(-tailLength);

  // Move a trailing space on the first part to the last part
  if (firstPart.endsWith(' ')) {
    firstPart = firstPart.slice(0, -1);
    lastPart = ' ' + lastPart;
  }

  return [firstPart, lastPart];
}

function pluralize(count, singular, plural = '') {
  const word = count === 1 ? singular : plural || singular + 's'
  return `${count} ${word}`
}
