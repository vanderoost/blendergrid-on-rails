import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list"]

  connect() {
    this.bound = {
      initUpload: this.initUpload.bind(this),
      progress: this.progress.bind(this),
      error: this.error.bind(this),
      end: this.end.bind(this),
    }

    this.element.addEventListener("direct-upload:initialize", this.bound.initUpload)
    this.element.addEventListener("direct-upload:progress", this.bound.progress)
    this.element.addEventListener("direct-upload:error", this.bound.error)
    this.element.addEventListener("direct-upload:end", this.bound.end)

    this.items = new Map()
  }

  disconnect() {
    this.element.removeEventListener("direct-upload:initialize", this.bound.initUpload)
    this.element.removeEventListener("direct-upload:progress", this.bound.progress)
    this.element.removeEventListener("direct-upload:error", this.bound.error)
    this.element.removeEventListener("direct-upload:end", this.bound.end)
  }

  initUpload(e) {
    const { id, file } = e.detail
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

  progress(e) {
    const { id, progress } = e.detail
    const el = this.items.get(id)
    if (el) el.querySelector("[data-progress]").value = progress
  }

  error(e) {
    const { id, error } = e.detail
    const el = this.items.get(id)
    if (el) {
      el.insertAdjacentText("beforeend", ` — failed: ${error}`)
      el.querySelector("[data-progress]")?.remove()
      this.items.delete(id)
    }
  }

  end(e) {
    const { id } = e.detail
    const el = this.items.get(id)
    if (el) {
      const bar = el.querySelector("[data-progress]")
      if (bar) bar.value = 100
      this.items.delete(id)
    }
  }
}
