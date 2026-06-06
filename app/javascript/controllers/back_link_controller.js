import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { uploadId: String }
  static targets = ["link"]

  linkTargetConnected(link) {
    if (!this.uploadIdValue) return
    const url = new URL(link.href)
    if (url.searchParams.has("upload_id")) return
    url.searchParams.set("upload_id", this.uploadIdValue)
    link.href = url.href
  }
}
