# Blendergrid on Rails

Live at: [rails.blendergrid.com](https://rails.blendergrid.com)

A proof of concept re-write of the Blendergrid.com Web App in Rails.

## Versions

Rails version: 8.0.2
Rack version: 3.1.12
Ruby version: 3.4.2

## System dependencies

For running locally, making web sockets work you need to have Redis installed.

Mac:
```bash
brew install redis
```

Linux:
```bash
sudo apt-get install redis-server
```

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

* Services (job queues, cache servers, search engines, etc.)

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

