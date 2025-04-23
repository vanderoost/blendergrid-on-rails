# Blendergrid on Rails

Writing a Blendergrid Web App in Rails.

## Setup (Mac)
How this app was initially set up.

1. Install a bunch of dependencies

```bash
brew install openssl@3 libyaml gmp rust
```

2. Mise version manager

```bash
curl https://mise.run | sh
```

Add this to .zshrc

```bash
eval "$(~/.local/bin/mise activate)"
```

3. Install Ruby with Mise

```bash
mise use -g ruby@3
```

4. Install Rails

```bash
gem install rails
```

5. Create a new Rails app

```bash
rails new --name=blendergrid --css=tailwind .
```

## Versions

Rails version: 8.0.2
Rack version: 3.1.12
Ruby version: ruby 3.4.2

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

* Database initialization

* How to run the test suite

## Running locally

```bash
bin/dev
```

* Services (job queues, cache servers, search engines, etc.)

## Deployment instructions
```bash
kamal deploy

```

## Monitoring

Live tailing logs
```bash
kamal logs
```
