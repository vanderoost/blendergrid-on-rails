import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.loadBeacon();
  }

  loadBeacon() {
    !function(e, t, n) {
      function a() {
        var e = t.getElementsByTagName("script")[0],
          n = t.createElement("script");
        n.type = "text/javascript";
        n.async = !0;
        n.src = "https://beacon-v2.helpscout.net";
        e.parentNode.insertBefore(n, e)
      }
      if (e.Beacon = n = function(t, n, a) {
        e.Beacon.readyQueue.push({ method: t, options: n, data: a })
      }, n.readyQueue = [], "complete" === t.readyState) return a();
      e.attachEvent ? e.attachEvent("onload", a) : e.addEventListener(
        "load", a, !1
      )
    }(window, document, window.Beacon || function() { });
    window.Beacon('init', '6b97cb1f-6f6b-47d0-a5bc-99cf8bdf6f99')
  }
}
