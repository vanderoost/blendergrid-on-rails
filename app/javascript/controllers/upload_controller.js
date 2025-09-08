import { Controller } from "@hotwired/stimulus"

const states = {
  idle: "idle",
  ready: "ready",
  uploading: "uploading",
  done: "done",
}
export default class extends Controller {
  static targets = ["input", "list", "submit", "summary",]
  static values = { status: String }

  connect() {
    console.log("UploadController connected")

    this.fileItemsByName = new Map()
    this.items = new Map()
    this.totalSize = 0
    this.uploadedSizes = new Map()
    this.smoothEta = null
    this.etaCalcDelay = 3000
    this.startTime = 0
  }

  showFiles() {
    if (this.statusValue === states.uploading) {
      console.error("Cannot change the files, already uploading")
      return
    }

    const files = this.inputTarget.files
    console.debug("files:", files)

    this.listTarget.innerHTML = ""
    for (var i = 0; i < files.length; i++) {
      const file = files[i]
      this.totalSize += file.size
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
              class="text-indigo-600 dark:text-indigo-500 stroke-current progress_donut"
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

    this.submitTarget.disabled = files.length === 0
    this.submitTarget.value = `Upload ${pluralize(files.length, "File")}`

    if (files.length > 0) {
      this.statusValue = states.ready
    }

    console.debug("statusValue:", this.statusValue)
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

  uploadInit(event) {
    const { file } = event.detail
    this.totalSize += file.size
  }

  uploadProgress(e) {
    const { id, file, progress } = e.detail
    this.uploadedSizes.set(id, Math.round(file.size * progress / 100))
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
      console.debug("calculating eta")
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
