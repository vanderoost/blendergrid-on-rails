import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]

  connect() {
    console.debug("connect FAQ")
  }

  toggle(event) {
    const item = this.itemTargets[event.params.index]
    item.hidden = !item.hidden
  }
}
