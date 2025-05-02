# Blendergrid on Rails

[![CI](https://github.com/vanderoost/blendergrid-on-rails/actions/workflows/ci.yml/badge.svg)](https://github.com/vanderoost/blendergrid-on-rails/actions/workflows/ci.yml)

A proof of concept re-write of the Blendergrid.com Web App in Rails.

[Check the Demo Screencast](https://vimeo.com/1080902705/f13f9968d7)
[![Demo Screencast](https://i.vimeocdn.com/video/2011590551-851fdc17aa70d9917d09bcf1c9c4d872f3dbf4c211452271ba7dc5e1cd2bd276-d_1280x720)](https://vimeo.com/1080902705/f13f9968d7)

Live at: [rails.blendergrid.com](https://rails.blendergrid.com)

## Versions

- Rails version: 8.0.2
- Rack version: 3.1.12
- Ruby version: 3.4.2

## Configuration

Update secrets and credentials
```bash
rails credentials:edit 
```

For specific environments
```bash
rails credentials:edit -e production
```

## Database

### Creation

Locally:
```bash
rails db:create
```

In production, Kamal takes care of this.

### Initialization

* How to run the test suite

## Running locally

Running a local server (using foreman for both web and tailwind refreshes)

```bash
bin/dev
```

Also make sure Redis is running for websockets (Turbo Streams over ActionCable) to work.

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

```bash
kamal deploy
```

## Monitoring

Live tailing production logs
```bash
kamal logs
```

Opening a shell in the web app Docker container
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

