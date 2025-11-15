import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  timing = {
    step: 10,
    enter: 400,
    hold: 4000,
    leave: 200,
  }

  transition = {
    enter: "transform ease-out duration-400 transition",
    enterFrom: "translate-y-4 opacity-0 sm:translate-y-0 sm:translate-x-4",
    enterTo: "translate-y-0 opacity-100 sm:translate-x-0",
    leave: "transition ease-in duration-200",
    leaveFrom: "opacity-100",
    leaveTo: "opacity-0",
  }

  panelTargetConnected() {
    this.open();

    setTimeout(this.close, this.timing.enter + this.timing.hold);
  }

  open = () => {
    // Setup enter from position
    this.transition.enterFrom.split(" ").forEach(className => {
      this.panelTarget.classList.add(className)
    })

    // Setup enter animation
    setTimeout(() => {
      this.transition.enter.split(" ").forEach(className => {
        this.panelTarget.classList.add(className)
      })
    }, this.timing.step);

    // Go to enter to position
    setTimeout(() => {
      this.transition.enterTo.split(" ").forEach(className => {
        this.panelTarget.classList.add(className)
      })
      this.transition.enterFrom.split(" ").forEach(className => {
        this.panelTarget.classList.remove(className)
      })
    }, this.timing.step * 2)

    // Cleanup and prepare for leave
    setTimeout(() => {
      this.transition.enter.split(" ").forEach(className => {
        this.panelTarget.classList.remove(className)
      })
      this.transition.leave.split(" ").forEach(className => {
        this.panelTarget.classList.add(className)
      })
      this.transition.leaveFrom.split(" ").forEach(className => {
        this.panelTarget.classList.add(className)
      })
    }, this.timing.enter + this.timing.step * 3)
  }

  close = () => {
    this.transition.leaveTo.split(" ").forEach(className => {
      this.panelTarget.classList.add(className)
    })
    this.transition.leaveFrom.split(" ").forEach(className => {
      this.panelTarget.classList.remove(className)
    })

    setTimeout(() => this.element.remove(), this.timing.leave + this.timing.step);
  }
}
