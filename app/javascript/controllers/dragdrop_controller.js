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

    console.log('Drop event, adding files:', event.dataTransfer.files.length)
    this.#addFiles(event.dataTransfer.files);

    if (this.isDraggingValue) {
      this.isDraggingValue = false
    }

    console.log('Calling showFiles after drop')
    this.uploadOutlet.showFiles()
  }

  #addFiles(fileArray) {
    const dataTransfer = new DataTransfer();

    const originalFiles = [...this.inputTarget.files];
    console.log('Original files in input:', originalFiles.length)
    originalFiles.forEach(file => dataTransfer.items.add(file));

    const newFiles = [...fileArray];
    console.log('New files to add:', newFiles.length)
    newFiles.forEach(file => dataTransfer.items.add(file));

    this.inputTarget.files = dataTransfer.files;
    console.log('Input now has files:', this.inputTarget.files.length)

    // Trigger change event so ActiveStorage picks up the new files
    console.log('Dispatching change event')
    const event = new Event('change', { bubbles: true })
    this.inputTarget.dispatchEvent(event)
  }
}
