import { Controller } from "@hotwired/stimulus"
import { pluralize } from "application"

// Track active DirectUpload instances globally so we can cancel them
// DirectUpload has built-in abort() support (from Rails fork)
if (!window.activeDirectUploads) {
  window.activeDirectUploads = new Map()
}

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
    this.fileNameToUploadId = new Map() // Track filename -> upload ID
    this.items = new Map()
    this.totalSize = 0
    this.uploadedSizes = new Map()
    this.smoothEta = null
    this.etaCalcDelay = 3000
    this.startTime = 0
    this.activeUploadCount = 0 // Track how many uploads are active

    // Add form submit listener for debugging
    this.element.addEventListener('submit', (e) => {
      console.log('Form submit event fired!', {
        files: this.inputTarget.files.length,
        status: this.statusValue
      })
    })

    // Add button click listener for debugging
    this.submitTarget.addEventListener('click', (e) => {
      console.log('Submit button clicked!', {
        disabled: this.submitTarget.disabled,
        status: this.statusValue
      })
    })
  }

  // Called on file input change
  // Should just care about presentation, don't keep track of
  // total file size here
  showFiles() {
    console.log('showFiles called, status:', this.statusValue)
    console.log('Input has files:', this.inputTarget.files.length)
    console.log('Input element:', this.inputTarget)
    if (this.statusValue === states.uploading) {
      console.log('Blocked by uploading state')
      return
    }
    const files = this.inputTarget.files

    this.listTarget.innerHTML = ""
    for (var i = 0; i < files.length; i++) {
      const file = files[i]
      const [filenameHead, filenameTail] = splitFilename(file.name)
      const fileElement = document.createElement("div")
      fileElement.className =
        "flex items-center justify-between gap-x-3 p-3 text-sm"
      fileElement.dataset.fileName = file.name
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
              class="text-primary-600 dark:text-primary-500
               stroke-current progress_donut"
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
        <div class="text-gray-500 dark:text-gray-400">
          ${humanFileSize(file.size)}
        </div>
        <button
          type="button"
          data-action="click->upload#removeFile"
          class="flex-none text-gray-400 hover:text-gray-600
           dark:text-gray-500 dark:hover:text-gray-300
           transition-colors"
          title="Remove file"
        >
          <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24"
           stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round"
             d="M6 18 18 6M6 6l12 12" />
          </svg>
        </button>
      `
      this.listTarget.appendChild(fileElement)
      this.fileItemsByName.set(file.name, fileElement)
    }

    if (files.length > 0) {
      this.statusValue = states.ready
      this.listTarget.classList.remove("hidden")
      this.submitTarget.disabled = false
      this.submitTarget.value = `Upload ${pluralize(files.length, "File")}`
      console.log('Files ready to upload:', {
        fileCount: files.length,
        status: this.statusValue,
        buttonDisabled: this.submitTarget.disabled
      })
    } else {
      this.statusValue = states.empty
      this.listTarget.classList.add("hidden")
      this.submitTarget.disabled = true
      this.submitTarget.value = "Upload Files"
    }

  }

  removeFile(event) {
    event.preventDefault()

    const button = event.currentTarget
    const fileItem = button.closest('[data-file-name]')
    const fileNameToRemove = fileItem.dataset.fileName

    if (this.statusValue === states.uploading) {
      // Cancel the active upload using built-in abort() method
      const upload = window.activeDirectUploads.get(fileNameToRemove)
      if (upload) {
        // Call the built-in abort method from Rails fork
        // This will trigger uploadError which handles cleanup
        upload.abort()

        // Update tracking - remove this file's contribution
        const uploadId = this.fileNameToUploadId.get(fileNameToRemove)
        if (uploadId) {
          this.uploadedSizes.delete(uploadId)
          this.fileNameToUploadId.delete(fileNameToRemove)
        }

        // Reduce total size by this file's size
        this.totalSize -= upload.file.size
      }

      // Remove the file item from display
      fileItem.remove()
      this.fileItemsByName.delete(fileNameToRemove)

      console.log('After remove:', {
        filesRemaining: this.fileItemsByName.size,
        activeUploads: this.activeUploadCount,
        status: this.statusValue
      })

      // Recalculate progress with remaining files
      if (this.fileItemsByName.size > 0) {
        this.trackTotalProgress()
      } else {
        // No files left, check if we should reset
        this.checkIfAllUploadsComplete()
      }

    } else {
      // Before upload: remove from file input
      const dt = new DataTransfer()
      const files = Array.from(this.inputTarget.files)

      files.forEach(file => {
        if (file.name !== fileNameToRemove) {
          dt.items.add(file)
        }
      })

      // Update the input with the new file list
      this.inputTarget.files = dt.files

      // Refresh the UI
      this.showFiles()
    }
  }

  uploadsStart() {
    console.log('uploadsStart called, current status:', this.statusValue)
    if (this.statusValue !== states.uploading) {
      this.statusValue = states.uploading
      this.submitTarget.disabled = true
      this.submitTarget.value =
        `Uploading ${pluralize(this.inputTarget.files.length, "File")}`
      console.log('Status changed to uploading')
    }

    if (this.startTime === 0) {
      this.startTime = Date.now()
    }
  }

  // Called on: direct-upload:initialize
  uploadInit(event) {
    const { id, file, upload } = event.detail
    console.log('uploadInit called for file:', file.name)
    this.totalSize += file.size
    this.fileNameToUploadId.set(file.name, id)
    this.activeUploadCount++
    console.log('Active upload count:', this.activeUploadCount)

    // Store the DirectUpload instance so we can abort it later
    if (upload) {
      window.activeDirectUploads.set(file.name, upload)
    }
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
    const bytesDone =
      Array.from(this.uploadedSizes.values()).reduce(
        (acc, n) => acc + n, 0)

    // Guard against division by zero
    if (this.totalSize <= 0) {
      return
    }

    const percent = Math.min(100, bytesDone / this.totalSize * 100)

    this.summaryTarget.querySelector(".percentage").innerHTML =
      `Uploading: ${percent.toFixed(1)}%`
    this.summaryTarget.querySelector(".upload_progress").style.width =
      `${percent.toFixed(1)}%`

    const now = Date.now()
    const elapsed = now - this.startTime

    if (elapsed > this.etaCalcDelay && bytesDone > 0) {
      const bytesRemaining = this.totalSize - bytesDone
      if (bytesRemaining > 0) {
        const eta = now + elapsed / bytesDone * bytesRemaining

        if (this.smoothEta === null) {
          this.smoothEta = eta
        } else {
          this.smoothEta = 0.99 * this.smoothEta + 0.01 * eta
        }
        const remaining = this.smoothEta - now
        this.summaryTarget.querySelector(".eta").innerHTML =
          `About ${humanDuration(remaining)} remaining`
      }
    }

    if (this.summaryTarget.classList.contains("hidden")) {
      this.summaryTarget.classList.remove("hidden")
      this.summaryTarget.classList.add("flex")
    }
  }

  uploadError(e) {
    const { id, error, file } = e.detail

    // Prevent default alert for aborted uploads (user cancelled them)
    if (error && error.toString().includes("Upload aborted")) {
      e.preventDefault()
    }

    // Clean up stored upload instance
    if (file) {
      window.activeDirectUploads.delete(file.name)
    }

    const el = this.items.get(id)
    if (el) {
      el.insertAdjacentText("beforeend", ` — failed: ${error}`)
      el.querySelector("[data-progress]")?.remove()
      this.items.delete(id)
    }
    this.activeUploadCount = Math.max(0, this.activeUploadCount - 1)
    this.checkIfAllUploadsComplete()
  }

  uploadEnd(e) {
    const { id, file } = e.detail

    // Clean up stored upload instance
    if (file) {
      window.activeDirectUploads.delete(file.name)
    }

    const el = this.items.get(id)
    if (el) {
      const bar = el.querySelector("[data-progress]")
      if (bar) bar.value = 100
      this.items.delete(id)
    }
    this.activeUploadCount = Math.max(0, this.activeUploadCount - 1)
    this.checkIfAllUploadsComplete()
  }

  checkIfAllUploadsComplete() {
    console.log('checkIfAllUploadsComplete:', {
      activeUploadCount: this.activeUploadCount,
      status: this.statusValue,
      filesRemaining: this.fileItemsByName.size
    })

    // If all uploads are done (completed, failed, or cancelled)
    // and form is still in uploading state
    if (this.activeUploadCount <= 0 &&
        this.statusValue === states.uploading) {

      if (this.fileItemsByName.size === 0) {
        // All files were cancelled - reset the form
        console.log('Resetting form - all files cancelled')
        this.resetForm()
      }
      // If some files uploaded successfully or are still queued,
      // let ActiveStorage handle it - the Rails fork now properly
      // manages the queue
    }
  }

  resetForm() {
    // Use Turbo to visit the current page, which fetches it fresh from
    // the server This resets all JavaScript state (including ActiveStorage)
    // but feels smoother than a hard reload
    if (typeof Turbo !== 'undefined') {
      Turbo.visit(window.location.href)
    } else {
      window.location.reload()
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

