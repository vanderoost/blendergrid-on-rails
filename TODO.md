# TODOs

## before launch

- [ ]  Share invoices / receipts with users?
- [ ]  Show scene warnings (in settings?)
- [ ]  Deleting a project
- [ ]  Duplicating a project
- [ ]  Soft delete feature for certain models (projects, ?)
- [ ]  Calculate the deadline range based on the Benchmark and tweaks
- [ ]  Consistent Price calculation with the old web app
- [ ]  Take deadline into account when submitting an Order
- [ ]  Credit lead magnets: Capture email and give free credit gift.
- [ ]  Waiting stage
    - [ ]  Edit page with preview renders, deadline+res+samples form
    - [x]  Show price at index per project
    - [x]  Deadline + resolution + samples form at index
- [x]  UI/UX
    - [x]  Pay once for multiple projects
    - [x]  Basic style so it doesn’t look like a 90’s primary school website
- [x]  Emails
    - [x]  Capture email address of guests
    - [x]  Send project status emails
    - [x]  Send sign-up confirmation email
    - [x]  Send password reset emails
- [x]  Edit project settings
    - [x]  Between first check and benchmark
    - [x]  Between benchmark and render
- [x]  Support >20GB uploads through the website
- [x]  Use an external database (AWS RDS? Mysql / Postgres)
- [x]  Transfer over articles and affiliate landing pages
- [x]  Clean up old ECR images
- [x]  Track visits and affiliate clicks in the backend
- [x] Buying render credit through Stripe
- [x] Secure the API with some kind of token
- [x] Add privacy, terms, cookie policy pages
- [x]  Drag ‘n Drop uploads
- [x]  Auto submit Projects settings form: Make sure you can type and don't lose focus.
- [x]  Stimulus turbo stream fallback (poll a turbo frame in case we missed a stream)
- [x]  Finish the Project List View entirely
    - [x]  Give projects in each stage a link to the project show/edit page
    - [x]  Show total price of all checked projects (Stimulus)
    - [x]  Show resolution at the Uploaded projects stage
    - [x]  Disable 'Edit' link in all stages where it doesn't make sense
    - [x]  Empty projects page (no project yet! message)
    - [x]  Fix long project names overflowing the table
    - [x]  Add `stage_updated_at` to Projects to make ordering more deterministic
    - [x]  Show simple render progress and ETA
    - [x]  Give the project index page a minimum height
- [x]  Websockets security (don't send project updates to the wrong user/session)
- [x]  Integrate support chat (helpscout?)
- [x]  Make all session Uploads belong to the user when they log in?


## after launch

- [ ] Read available Blender versions form DockerHub and make them available to choose from?
- [ ]  Disable checkbox if there's only one Project in a stage
- [ ]  Add handwritten hints to the UI with arrows
    - [ ]  Select a project
    - [ ]  Calculate the price
    - [ ]  Start rendering
