import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  show(event) {
    if (event.target.children.length === 1) {
      this.load(event.target)
      event.target.children[0].hidden = false
    }
  }

  hide(event) {
    if (event.target.children.length === 1) {
      event.target.children[0].hidden = true
    }
  }

  // Set src from data-src the first time a tile is hovered, so thumbnails
  // are only fetched on demand instead of all at once on page load.
  load(tile) {
    tile.querySelectorAll("img[data-src]").forEach((img) => {
      img.src = img.dataset.src
      delete img.dataset.src
    })
  }
}
