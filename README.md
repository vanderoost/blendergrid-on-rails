# Blendergrid on Rails

A proof of concept re-write of the Blendergrid.com Web App in Rails.

## Versions

Rails version: 8.0.2
Rack version: 3.1.12
Ruby version: 3.4.2

* System dependencies

## Configuration

Update secrets and credentials
```bash
rails credentials:edit 
```

For specific environments
```bash
rails credentials:edit -e production
```

* Database creation

Locally:
```bash
rails db:create
```

In production, Kamal takes care of this.

* Database initialization

* How to run the test suite

## Running locally

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

### Running a console

Locally:
```bash
rails console
```

In production:
```bash
kamal console
```

