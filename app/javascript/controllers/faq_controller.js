import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.clickedIds = new Set()
    this.token = document.querySelector('meta[name="csrf-token"]').content
  }

  toggle(event) {
    const id = event.params.id
    const item = event.currentTarget.closest("dt").nextElementSibling
    const isExpanding = item.hidden

    item.hidden = !item.hidden

    if (isExpanding && !this.clickedIds.has(id)) {
      this.clickedIds.add(id)
      fetch(`/faqs/${id}`, {
        method: "PUT",
        headers: {
          "X-CSRF-Token": this.token,
          "Content-Type": "application/json",
        },
      })
    }
  }
}
