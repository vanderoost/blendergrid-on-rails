import { Controller } from "@hotwired/stimulus"

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
    let projectCheckedCount = 0
    let totalPriceCents = 0
    this.projectTargets.forEach(project => {
      const checkbox = project.querySelector("input[type=checkbox]")
      if (!checkbox.checked) return

      projectCheckedCount += 1
      totalPriceCents += parseInt(project.querySelector("[data-price-cents]").dataset.priceCents)
    })

    if (projectCheckedCount === 0) {
      this.summaryDisplayTarget.innerText = "select a project to start rendering"
    } else {
      this.summaryDisplayTarget.innerText = `total for ${projectCheckedCount} projects: $${(totalPriceCents / 100).toFixed(2)} USD`
    }
  }
}
