import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"];
  static outlets = ["upload"];

  connect() {
    console.log("DragDropController connected")
  }

  dragOver(event) {
    console.debug("dragOver")
    event.preventDefault();
  }

  dragLeave(event) {
    console.debug("dragLeave")
    event.preventDefault();
  }

  drop(event) {
    console.debug("drop")
    event.preventDefault();

    this.#updateInputField(event.dataTransfer.files);

    this.uploadOutlet.showFiles()
  }

  #updateInputField(files) {
    this.inputTarget.files = files;
  }
}
