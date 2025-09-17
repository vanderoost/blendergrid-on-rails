import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"];
  static outlets = ["upload"];
  static values = { isDragging: Boolean }

  dragOver(event) {
    event.preventDefault();

    if (!this.isDraggingValue) {
      this.isDraggingValue = true
    }
  }

  dragLeave(event) {
    event.preventDefault();

    if (this.isDraggingValue) {
      this.isDraggingValue = false
    }
  }

  drop(event) {
    event.preventDefault();

    this.#addFiles(event.dataTransfer.files);

    if (this.isDraggingValue) {
      this.isDraggingValue = false
    }

    this.uploadOutlet.showFiles()
  }

  #addFiles(fileArray) {
    const dataTransfer = new DataTransfer();

    console.debug("Add the original files to the DataTransfer object")
    const originalFiles = [...this.inputTarget.files];
    originalFiles.forEach(file => dataTransfer.items.add(file));
    console.debug("dataTransfer.files:", dataTransfer.files)

    console.debug("Add the new files to the DataTransfer object")
    const newFiles = [...fileArray];
    newFiles.forEach(file => dataTransfer.items.add(file));
    console.debug("dataTransfer.files:", dataTransfer.files)

    this.inputTarget.files = dataTransfer.files;
  }
}
