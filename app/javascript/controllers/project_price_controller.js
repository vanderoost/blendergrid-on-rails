import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["priceCents", "priceDisplay"]

  connect() {
    console.debug("ProjectPriceController#connect")
    this.refreshPrice()
  }

  refreshPrice() {
    if (this.priceCentsTarget.dataset.priceCents > 0) {
      const priceString = (this.priceCentsTarget.dataset.priceCents / 100).toFixed(2);
      this.priceDisplayTarget.innerText = `$${priceString} USD`
    } else {
      console.warn("No price found")
      this.priceDisplayTarget.innerText = ""
    }
  }
}
