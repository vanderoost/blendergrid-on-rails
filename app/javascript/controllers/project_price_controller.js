import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["priceCents", "priceDisplay"]

  connect() {
    this.element.addEventListener("turbo:frame-render", this.#refreshPrice)
    this.#refreshPrice()
  }

  disconnect() {
    this.element.removeEventListener("turbo:frame-render", this.#refreshPrice)
  }

  #refreshPrice = () => {
    if (this.priceCentsTarget.dataset.priceCents > 0) {
      const priceString = (this.priceCentsTarget.dataset.priceCents / 100).toFixed(2);
      this.priceDisplayTarget.innerText = `$${priceString} USD`
    } else {
      console.error("No price found")
      this.priceDisplayTarget.innerText = ""
    }
  }
}
