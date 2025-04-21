import { Controller } from "@hotwired/stimulus"

const MAX_FILE_NAME_LENGTH = 36

export default class extends Controller {
  static targets = [
    "uploadArea",
    "fileInput",
    "fileList",
    "fileItemTemplate",
    "submit",
    "project",
  ]
  static values = { highlightCounter: Number }

  files = []
  blendFileCount = 0
  hasEmail = false

  connect() {
    console.info("Upload controller connected :D")
  }

  addHighlight(event) {
    event.preventDefault()
    this.highlightCounterValue++

    const files = eventFiles(event)
    console.debug(`addHighlight - ${this.highlightCounterValue} - Dragging ${files.length} file(s)`)
  }

  removeHighlight(event) {
    event.preventDefault()
    this.highlightCounterValue--

    console.debug("removeHighlight - ", this.highlightCounterValue)
  }

  highlightCounterValueChanged() {
    this.element.setAttribute("data-highlight", !!this.highlightCounterValue)
  }

  disableDefaultDrag(event) { event.preventDefault(); }

  addDroppedFiles(event) {
    event.preventDefault()
    this.highlightCounterValue = 0

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

  emailChanged(event) {
    console.debug("emailChanged", event.target.value)
    this.hasEmail = isValidEmail(event.target.value)

    this.checkForm(event.target.form)
  }

  updateFileList() {
    console.debug("updateFileList")

    if (this.files.length > 0) {
      this.fileListTarget.classList.remove("hidden")

    } else {
      this.fileListTarget.classList.add("hidden")
      return
    }

    const mainBlendFileMask = this.projectTargets.map((project) => project.checked)
    this.fileListTarget.innerHTML = ""
    this.files.forEach(
      (file, index) => this.addFileItem(file, index, mainBlendFileMask)
    )
  }

  checkForm() {
    console.debug("checkForm")
    console.debug("blendFileCount", this.blendFileCount)
    console.debug("hasEmail", this.hasEmail)

    if (this.blendFileCount > 0 && this.hasEmail) {
      this.submitTarget.removeAttribute("disabled")
    } else {
      this.submitTarget.setAttribute("disabled", true)
    }
  }

  addFileItem(file, index, mainBlendFileMask) {
    console.debug("addFileItem", file)

    const template = this.fileItemTemplateTarget.content.cloneNode(true)
    const checkboxElem = template.querySelector("#checkbox")
    const checkboxContainer = template.querySelector("#checkbox-container")
    const fileNameElem = template.querySelector("#file-name")
    const fileSizeElem = template.querySelector("#file-size")

    checkboxElem.setAttribute("id", `file-${index}`)
    checkboxElem.setAttribute("aria-describedby", `file-${index}-name`)
    checkboxElem.value = index
    checkboxElem.checked = isBlendFile(file) && (
      mainBlendFileMask[index] || this.blendFileCount < 2)
    checkboxElem.hidden = !isBlendFile(file) || this.blendFileCount < 2

    checkboxContainer.removeAttribute("id")
    if (this.blendFileCount < 2)
      checkboxContainer.classList.add("hidden")
    else
      checkboxContainer.classList.remove("hidden")

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
    console.debug("submit", event)
  }
}

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
