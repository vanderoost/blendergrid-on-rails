import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"];
  static outlets = ["upload"];
  static values = { isDragging: Boolean }

  connect() {
    console.log("DragDropController connected")
  }

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

    this.#updateInputField(event.dataTransfer.files);

    if (this.isDraggingValue) {
      this.isDraggingValue = false
    }

    this.uploadOutlet.showFiles()
  }

  #updateInputField(files) {
    this.inputTarget.files = files;
  }
}
