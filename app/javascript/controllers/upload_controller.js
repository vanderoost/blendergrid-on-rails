import { Controller } from "@hotwired/stimulus"

const MAX_FILE_NAME_LENGTH = 32

export default class extends Controller {
  static targets = [
    "uploadArea",
    "fileInput",
    "fileList",
    "fileItemTemplate",
    "email",
    "submit",
    "submitText",
    "project",
  ]
  static values = {
    dragCounter: Number,
    isDragging: Boolean,
    isSubmitting: Boolean,
    isUploading: Boolean,
  }

  files = []
  blendFileCount = 0
  hasEmail = false
  bytesTotal = 0
  bytesUploaded = []

  connect() {
    addEventListener("direct-upload:progress", (e) => this.uploadProgress(e))
    this.checkForm()

    // Debug - Show fake files from the start
    //this.files = [
    //  { name: "test.blend", size: 12345 },
    //  { name: "another.blend", size: 4312 },
    //]
    //this.updateFileList()
  }

  addDrag(event) {
    event.preventDefault()
    this.dragCounterValue++
  }

  removeDrag(event) {
    event.preventDefault()
    this.dragCounterValue--
  }

  dragCounterValueChanged() {
    this.isDraggingValue = this.dragCounterValue > 0
  }

  disableDefaultDrag(event) { event.preventDefault(); }

  addDroppedFiles(event) {
    event.preventDefault()
    this.dragCounterValue = 0

    console.debug(`New file(s) dropped`)

    this.filesChanged(event)
  }

  filesChanged(event) {
    console.debug("filesChanged", event)

    const newFiles = eventFiles(event)

    this.files.push(...newFiles)
    this.blendFileCount = this.files.filter(isBlendFile).length

    const dataTransfer = new DataTransfer(this.files)
    this.files.forEach((file) => dataTransfer.items.add(file))
    this.fileInputTarget.files = dataTransfer.files

    this.updateFileList()

    this.checkForm(event.target.form)

    console.debug(this.projectTargets)
  }

  emailChanged() {
    this.checkForm()
  }

  updateMainBlendFiles() {
    this.checkForm()
  }

  updateFileList() {
    if (this.files.length > 0) {
      this.fileListTarget.classList.remove("hidden")

    } else {
      this.fileListTarget.classList.add("hidden")
      return
    }

    this.fileListTarget.innerHTML = ""
    this.files.forEach(
      (file, index) => this.addFileItem(file, index)
    )
  }

  checkForm() {
    if (this.mainBlendFileCount > 0 && isValidEmail(this.emailTarget.value)) {
      this.submitTarget.removeAttribute("disabled")
    } else {
      this.submitTarget.setAttribute("disabled", true)
    }

    if (this.mainBlendFileCount > 1) {
      this.submitTextTarget.textContent = `Start ${this.mainBlendFileCount} Renders`
    } else {
      this.submitTextTarget.textContent = `Start a Render`
    }
  }

  addFileItem(file, index) {
    console.debug("addFileItem", file)

    const template = this.fileItemTemplateTarget.content.cloneNode(true)
    const checkboxElem = template.querySelector("#checkbox")
    const checkboxWrapper = template.querySelector("#checkbox-wrapper")
    const progressDonutWrapper = template.querySelector("#progress-donut-wrapper")
    const progressDonutElem = template.querySelector("#progress-donut")
    const fileNameElem = template.querySelector("#file-name")
    const fileSizeElem = template.querySelector("#file-size")

    const hasMultipleBlendFiles = this.blendFileCount > 1

    checkboxWrapper.setAttribute("id", `checkbox-wrapper-${index}`)
    if (!hasMultipleBlendFiles)
      checkboxWrapper.classList.add("hidden")

    checkboxElem.setAttribute("id", `file-${index}`)
    checkboxElem.setAttribute("aria-describedby", `file-${index}-name`)
    checkboxElem.value = index
    checkboxElem.checked = isBlendFile(file) && (
      this.mainBlendFilesMask[index] || this.blendFileCount < 2)
    if (!isBlendFile(file))
      checkboxElem.classList.add("hidden")

    progressDonutWrapper.setAttribute("id", `progress-donut-wrapper-${index}`)
    progressDonutElem.setAttribute("id", `progress-donut-${index}`)
    if (hasMultipleBlendFiles)
      progressDonutWrapper.classList.add("hidden")

    fileNameElem.textContent = truncate(file.name, MAX_FILE_NAME_LENGTH)
    fileNameElem.setAttribute("title", file.name)
    fileNameElem.setAttribute("for", `file-${index}`)
    fileNameElem.setAttribute("id", `file-${index}-name`)

    fileSizeElem.textContent = humanFileSize(file.size)
    fileSizeElem.setAttribute("title", `${file.size} bytes`)
    fileSizeElem.removeAttribute("id")

    this.fileListTarget.appendChild(template)
  }

  submit(event) {
    console.debug("SUBMIT", event)

    if (!this.isUploadingValue) {
      this.isSubmittingValue = true
      this.submitTextTarget.textContent = `Preparing Upload${this.files.length > 1 ? "s" : ""}`
      this.bytesUploaded = Array(this.files.length).fill(0)
      this.bytesTotal = this.files.reduce((a, b) => a + b.size, 0)
      console.debug("bytesTotal", this.bytesTotal)
    }

    for (let index = 0; index < this.files.length; index++) {
      this.fileListTarget.querySelector(`#checkbox-wrapper-${index}`)
        .classList.add("hidden")
      this.fileListTarget.querySelector(`#progress-donut-wrapper-${index}`)
        .classList.remove("hidden")
    }
  }

  uploadProgress(event) {
    this.isSubmittingValue = false
    this.isUploadingValue = true

    const { file, progress } = event.detail
    const index = this.files.findIndex((f) => f.name === file.name)
    if (index === -1) return
    const donutLength = 150.8 * (1.0 - progress / 100.0)

    this.fileListTarget.querySelector(`#progress-donut-${index}`)
      .setAttribute("stroke-dashoffset", donutLength.toFixed(2))

    this.bytesUploaded[index] = Math.round(file.size * progress / 100.0)
    console.debug("bytesUploaded", this.bytesUploaded)
    this.totalUploaded = this.bytesUploaded.reduce((a, b) => a + b, 0)
    console.debug("totalUploaded", this.totalUploaded)
    const totalProgress = this.totalUploaded / this.bytesTotal
    this.submitTextTarget.textContent = `Uploading ${(totalProgress * 100).toFixed(0)}%`
  }

  get mainBlendFilesMask() {
    return this.projectTargets.map((project) => project.checked);
  }

  get mainBlendFileCount() {
    return this.projectTargets.filter((project) => project.checked).length;
  }
}

// Event listeners for upload progress and stuff

// Helpers
const eventFiles = (event) => {
  if (event.target?.files) {
    return Array.from(event.target.files)
  }

  if (event.dataTransfer?.files) {
    return Array.from(event.dataTransfer.files)
  }

  const files = []
  event.dataTransfer.items.forEach((item) => {
    if (item.kind === "file") {
      files.push(item.getAsFile())
    }
  })
  return files
}

const isBlendFile = (file) => file.name.endsWith(".blend")

const truncate = (str, n) => {
  if (str.length <= n) return str

  return `${str.slice(0, n / 2 - 1)}…${str.slice(str.length - n / 2)}`
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

const isValidEmail = (email) => {
  const emailPattern = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/

  return emailPattern.test(email)
}
