import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.debug("connect")
  }

  show(event) {
    if (event.target.children.length === 1) {
      event.target.children[0].hidden = false
    }
  }

  hide(event) {
    if (event.target.children.length === 1) {
      event.target.children[0].hidden = true
    }
  }
}
