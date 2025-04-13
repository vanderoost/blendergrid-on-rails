# Blendergrid on Rails

Writing a Blendergrid Web App in Rails.

## Setup (Mac)

Ensure brew is installed.

1. Install Stuff

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
