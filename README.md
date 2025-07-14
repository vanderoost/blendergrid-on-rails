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

Update credentials and secrets.
```bash
rails credentials:edit 
```

## Database

### Creation

Locally:
```bash
rails db:create
```

In production, Kamal takes care of this.

### Initialization

TODO

## How to run the test suite

One off tests:

```bash
rails test
```

Live testing on code changes:

```bash
bundle exec guard
```

## Running locally

### Server

Running a local server (using foreman for both web and tailwind refreshes)

```bash
bin/dev
```

Also make sure Redis is running for websockets (Turbo Streams over ActionCable) to work.

### Localstack & Terraform

Use `tfenv` to manage Terraform versions.

To install `tfenv`:
```bash
brew install tfenv
```

To install Terraform:
```bash
tfenv install
```
or
```bash
tfenv install latest
```

To use a specific version of Terraform:
```bash
tfenv use <version>
```

Make sure Localstack is running:
```bash
docker compose up -d
```

To build the infrastructure:
```bash
cd terraform
terraform init
terraform apply -auto-approve
```

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

### Nuking the server and starting from scratch

```bash
ssh ubuntu@rails.blendergrid.com

# On the server
/Users/richard/.ssh/known_hosts:1457
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

