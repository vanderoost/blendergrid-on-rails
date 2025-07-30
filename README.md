# Blendergrid on Rails [![CI](https://github.com/vanderoost/blendergrid-on-rails/actions/workflows/ci.yml/badge.svg)](https://github.com/vanderoost/blendergrid-on-rails/actions/workflows/ci.yml)

A proof of concept re-write of the Blendergrid.com Web App in Rails.

[Check the Demo Screencast](https://vimeo.com/1080902705/f13f9968d7)
[![Demo Screencast](https://i.vimeocdn.com/video/2011590551-851fdc17aa70d9917d09bcf1c9c4d872f3dbf4c211452271ba7dc5e1cd2bd276-d_1280x720)](https://vimeo.com/1080902705/f13f9968d7)

Live at: [rails.blendergrid.com](https://rails.blendergrid.com)

## Versions

- Rails version: 8.0.2
- Ruby version: 3.4.2

## Configuration

Make sure the `EDITOR` environment variable is set (`export EDITOR=vim`).

Update credentials and secrets:
```bash
RAILS_ENV=production bin/rails credentials:edit
```

For specific development credentials (if they differ from production), use:
```bash
rails credentials:edit -e development
```

## Database

### Creation

Locally:
```bash
rails db:create
```

In production, Kamal takes care of this.

### Initialization

Run `bin/setup` to create the database and initialize the test database.

## How to run the test suite

One off tests:

```bash
rails test
```

Automatic testing on code changes:

```bash
autotest
```

## Running locally

### Server

Running a local server (using foreman for both web and tailwind refreshes)

```bash
bin/dev
```

Also make sure Redis is running for websockets (Turbo Streams over ActionCable) to work.

### Email

Use Mailhog to run a local SMTP server.

To install Mailhog:

```bash
brew install mailhog
```

Then run `mailhog`, and open `http://localhost:8025` in your browser to see the inbox.

TODO: Maybe make this a command in `bin/` and/or run it automatically on bin/dev?

### Stripe

Make sure Stripe CLI is installed:

```bash
brew install stripe
```

Then run the webhook listener / forwarder for making Webhooks in the Sandbox work:

```bash
stripe listen --forward-to localhost:3000/webhooks/stripe
```

TODO: Maybe make this a command in `bin/` and/or run it automatically on bin/dev?

## Services (job queues, cache servers, search engines, etc.)

For running websockets locally, you need to have Redis installed.

Mac:
```bash
brew install redis
```

Linux:
```bash
sudo apt-get install redis-server
```

## Deployment instructions

Make sure the infrastructure is up and running.

```bash
infra
```

Manual deployment:

```bash
kamal deploy
```

Pushing to `main` will also trigger a deployment, configured in `.github/workflows/ci.yml`.

### Nuking the server and starting from scratch

```bash
bin/kamal remove -y && \
ssh ubuntu@rails.blendergrid.com \
  'docker volume rm $(docker volume ls -q | grep blendergrid)' && \
bin/kamal setup
```

## Monitoring

Live tailing production logs:

```bash
kamal logs
```

Opening a shell in the web app Docker container:

```bash
kamal shell
```

### Running a console

Locally:
```bash
rails console
```

In production:
```bash
kamal console
```

