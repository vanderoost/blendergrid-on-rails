import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["priceCents", "priceDisplay"]

  connect() {
    this.element.addEventListener("turbo:frame-render", this.#updatePrice)
    this.#updatePrice()
  }

  disconnect() {
    this.element.removeEventListener("turbo:frame-render", this.#updatePrice)
  }

  #updatePrice = () => {
    if (this.priceCentsTarget.dataset.priceCents > 0) {
      const priceString = (this.priceCentsTarget.dataset.priceCents / 100).toFixed(2);
      this.priceDisplayTarget.innerText = `$${priceString} USD`
    } else {
      console.error("No price found")
      this.priceDisplayTarget.innerText = ""
    }
  }
}
