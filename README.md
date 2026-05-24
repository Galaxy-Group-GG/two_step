# TwoStep

`two_step` is a mountable Rails engine that adds TOTP-based multi-factor authentication to session-based Rails apps. It stays out of the password step, so it works with custom authentication flows as well as libraries such as Clearance or Sorcery.

## Features

- TOTP verification compatible with Google Authenticator, 1Password, Authy, and similar apps
- QR-code enrollment with a manual setup key fallback
- One-time backup codes in the format `XXX-XXX-XXX-XXX-XXX`
- SHA-256 backup code digests by default, with configurable digest and verify hooks
- Replay protection through `last_otp_at`
- Mountable engine with isolated controllers, routes, views, locales, and assets
- Built-in English and Japanese copy plus a branded default UI
- Host-application hooks for resource lookup, redirects, layout metadata, and post-TwoStep session handling

## Requirements

- Ruby `>= 3.2`
- Rails `>= 7.1`, `< 9.0`

## Installation

Add the gem and install:

```ruby
gem "two_step"
```

```bash
bundle install
bin/rails generate two_step:install
bin/rails db:migrate
```

If you use a model other than `User`, pass it to the generator:

```bash
bin/rails generate two_step:install --model Admin
```

Include the concern in your authenticatable model:

```ruby
class User < ApplicationRecord
  include TwoStep::Models::Authenticatable
  encrypts :otp_secret
end
```

`encrypts :otp_secret` is recommended on Rails 7+ so the shared secret is not stored in plaintext.

Mount the engine:

```ruby
Rails.application.routes.draw do
  mount TwoStep::Engine => "/two_step"
end
```

The generator creates `config/initializers/two_step.rb` and a migration that adds:

- `otp_secret`
- `otp_required_for_login`
- `otp_backup_codes`
- `last_otp_at`

## Quick Start

The host app handles the password step first and redirects into the engine only when TwoStep is required.

```ruby
class SessionsController < ApplicationController
  def create
    user = User.authenticate_by(email: params[:email], password: params[:password])

    if user&.otp_enabled?
      reset_session
      session[:two_step_pending_user_id] = user.id
      redirect_to two_step.new_two_step_challenge_path
    elsif user
      reset_session
      session[:user_id] = user.id
      redirect_to dashboard_path
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end
end
```

The setup screen can be used from an already signed-in security settings page or from a pending-login flow. When setup succeeds for a pending-login user, the engine runs your `on_authentication_success` hook immediately.

## Routes

| Route | Purpose |
| --- | --- |
| `GET /two_step/setup/new` | Show the QR code, manual key, and enrollment form |
| `POST /two_step/setup` | Verify the first TOTP code, enable TwoStep, and reveal backup codes |
| `POST /two_step/setup/disable` | Disable TwoStep and clear secrets, backup codes, and replay state |
| `GET /two_step/challenge/new` | Prompt for a TOTP code or backup code |
| `POST /two_step/challenge` | Complete the TwoStep challenge |

`POST /two_step/setup/disable` also accepts an optional `return_to` parameter, but only relative paths beginning with `/` are honored.

## Configuration

The initializer is the public integration contract between the engine and your app:

```ruby
TwoStep.configure do |config|
  config.issuer = "MyApp"
  config.backup_code_count = 10
  config.qr_code_module_size = 4
  config.otp_drift_behind = 30
  config.otp_drift_ahead = 30

  config.resource_finder = ->(session) {
    User.find_by(id: session[:two_step_pending_user_id])
  }

  config.current_resource_finder = ->(session) {
    User.find_by(id: session[:user_id])
  }

  config.login_path = "/login"
  config.after_two_step_login_path = "/"

  config.on_authentication_success = ->(resource, session, _controller) {
    session.delete(:two_step_pending_user_id)
    session[:user_id] = resource.id
  }

  config.layout_title = -> { "#{config.issuer} Security" }
  config.layout_stylesheets = ["two_step/application"]
  config.layout_html_attributes = -> { {lang: I18n.locale} }
  config.layout_body_attributes = {class: "two_step-shell"}
  config.layout_brand = -> { config.issuer }
end
```

Notes:

- `resource_finder` and `current_resource_finder` may accept either `session` alone or `session, controller`.
- `login_path` can be a string or a callable that receives `controller`.
- `after_two_step_login_path` can be a string or a callable that receives `resource, controller`.
- `on_authentication_success` can accept `resource, session` or `resource, session, controller`.
- `layout_title`, `layout_stylesheets`, `layout_html_attributes`, `layout_body_attributes`, and `layout_brand` can be plain values or callables that receive `controller`.

Example using controller-aware hooks:

```ruby
TwoStep.configure do |config|
  config.login_path = ->(controller) { controller.main_app.login_path }
  config.after_two_step_login_path = ->(_resource, controller) { controller.main_app.dashboard_path }

  config.on_authentication_success = lambda do |resource, _session, controller|
    controller.reset_session
    controller.session[:user_id] = resource.id
  end

  config.layout_stylesheets = ["two_step/application", "two_step/host"]
  config.layout_body_attributes = ->(controller) {
    {class: "two_step-shell", data: {screen: controller.action_name}}
  }
end
```

## Backup Codes

Generated backup codes use uppercase letters and digits `2-9`, excluding ambiguous characters such as `I`, `L`, and `O`. Users can enter them with or without separators.

By default, the engine stores backup codes as SHA-256 digests and verifies them with a constant-time comparison:

```ruby
config.backup_code_digest_method = ->(normalized_code) {
  Digest::SHA256.hexdigest(normalized_code)
}

config.backup_code_verify_method = ->(normalized_code, hashed_code) {
  Rack::Utils.secure_compare(Digest::SHA256.hexdigest(normalized_code), hashed_code)
}
```

You can replace both hooks if your application needs a different storage strategy.

## Security Notes

- Encrypt `otp_secret` when your app supports Active Record encryption.
- Rotate the session after password authentication, and optionally again after TwoStep completes.
- Rate-limit both password and TwoStep endpoints in the host application.
- Treat backup codes like passwords: display them once, store them hashed, and never log them.
- The setup screen preserves an existing secret until TwoStep is explicitly disabled, which avoids breaking a user's authenticator app on refresh.

## Customization

- Override engine views by copying templates from `app/views/two_step/...` into the host app.
- Add host stylesheets and list them in `config.layout_stylesheets`.
- Customize page title, brand label, HTML attributes, and body attributes through the layout hooks.
- Use the controller-aware callbacks when you need host route helpers or custom session behavior.
- Switch locales through normal Rails I18n handling; the engine ships with English and Japanese translations.

## Development

This repository uses [Standard](https://github.com/standardrb/standard) with `standard-rails`.

```bash
bin/setup
bin/lint
bin/test
bundle exec rake coverage
docker compose build test
docker compose run --rm test
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines and [SECURITY.md](SECURITY.md) for responsible disclosure.

## License

MIT. See [MIT-LICENSE](MIT-LICENSE).
