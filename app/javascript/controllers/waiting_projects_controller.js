import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

export default class extends Controller {
  static targets = ["checkbox", "button"]

  connect = () => {
    window.stripe = Stripe(metaContent('stripe_key'));

    this.updateForm()
  }

  checkboxTargetConnected = () => this.updateForm()
  checkboxTargetDisconnected = () => this.updateForm()

  updateForm = () => {
    this.updateButton()

    const projectUuids = this.checkboxTargets.filter(checkbox => checkbox.checked).map(checkbox => checkbox.value)
    console.debug("Project UUIDs:", projectUuids)
    initializeStripe(projectUuids);

    if (this.checkboxTargets.length < 2) {
      this.checkboxTargets.forEach(checkbox => checkbox.classList.add("collapse"))
    } else {
      this.checkboxTargets.forEach(checkbox => checkbox.classList.remove("collapse"))
    }
  }

  updateButton = () => { this.buttonTarget.disabled = !this.formIsValid }

  get formIsValid() {
    return this.checkboxTargets.filter(checkbox => checkbox.checked).length > 0
  }
}

async function initializeStripe(projectUuids) {
  const fetchClientSecret = async () => {
    const response = await post("/stripe_checkout_sessions",
      { body: JSON.stringify({ project_uuids: projectUuids }) }
    );

    if (!response.ok) {
      throw new Error("Failed to create Stripe checkout session", response);
    }

    const { clientSecret } = await response.json;
    return clientSecret;
  };

  const checkout = await window.stripe.initEmbeddedCheckout({ fetchClientSecret });

  checkout.mount('#checkout');
}

function metaContent(name) {
  const element = document.head.querySelector(`meta[name="${name}"]`)
  return element && element.content
}
