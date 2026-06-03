import { Controller } from "@hotwired/stimulus"

// Submits the form it's attached to as soon as it connects. Used to make the
// marketing unsubscribe link one-click: the GET landing page auto-submits the
// unsubscribe form. Link prefetchers / scanners that don't run JS never fire it,
// and the visible button is the no-JS fallback.
export default class extends Controller {
  connect() {
    this.element.requestSubmit()
  }
}
