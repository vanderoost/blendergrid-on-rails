import { Controller } from "@hotwired/stimulus"
import { pluralize } from "application"

export default class extends Controller {
  static targets = ["projectsTable", "project", "summaryDisplay"]

  connect() {
    this.update()
  }

  projectsTableTargetConnected() {
    this.observer = new MutationObserver(this.update)
    this.observer.observe(this.projectsTableTarget, { subtree: true, childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  update = () => {
    let checkboxCount = 0
    let projectCheckedCount = 0
    let totalPriceCents = 0
    this.projectTargets.forEach(project => {
      const checkbox = project.querySelector("input[type=checkbox]")
      if (!!checkbox) checkboxCount += 1
      if (!checkbox || !checkbox.checked) return

      projectCheckedCount += 1
      totalPriceCents += parseInt(
        project.querySelector("[data-price-cents]").dataset.priceCents
      )
    })

    if (checkboxCount === 0) {
      this.summaryDisplayTarget.innerText = "please wait a few minutes for the price calculation to finish..."
    } else if (projectCheckedCount === 0) {
      this.summaryDisplayTarget.innerText = "select the projects you want to render"
    } else {
      this.summaryDisplayTarget.innerHTML = `
        <span class="text-gray-700 dark:text-gray-300">total for ${pluralize(projectCheckedCount, "project")}:</span>
        <span class="ml-3 tabular-nums">$${(totalPriceCents / 100).toFixed(2)} USD</span>
      `
    }
  }
}
