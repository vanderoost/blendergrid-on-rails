import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  files = [];
  hasBlendFile = false;
  hasEmail = false;

  connect() {
    console.log("Upload controller connected");
  }

  filesChanged(event) {
    console.log("filesChanged", event.target.files);

    this.files = Array.from(event.target.files);

    this.hasBlendFile = !!this.files.find(file => file.name.endsWith(".blend"))
    //const blendFiles = this.files.filter(file => file.name.endsWith(".blend"));
    //this.hasBlendFile = blendFiles.length > 0;

    this.checkForm(event.target.form);
  }

  emailChanged(event) {
    console.log("emailChanged", event);

    this.hasEmail = !!validateEmail(event.target.value);

    this.checkForm(event.target.form);
  }

  checkForm(form) {
    console.log("checkForm", form);
    console.debug("hasBlendFile", this.hasBlendFile);
    console.debug("hasEmail", this.hasEmail);

    if (this.hasBlendFile && this.hasEmail) {
      document.getElementById("submit").removeAttribute("disabled");
    } else {
      document.getElementById("submit").setAttribute("disabled", true);
    }
  }

  submit(event) {
    event.preventDefault();

    console.log("submit", event);
  }
}

const validateEmail = (email) => {
  return String(email)
    .toLowerCase()
    .match(
      /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
    );
};
