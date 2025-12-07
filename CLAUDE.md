# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Trades is a Rails 8.0 application for tracking counters. Users can create and increment their own counters through both a web interface and a JSON API.

**Stack:** Ruby 3.2.4, Rails 8.0.3, SQLite3, Devise, Hotwire (Turbo + Stimulus), Propshaft

## Common Commands

```bash
# Development
bundle install
rails db:create db:migrate
rails server

# Testing
rails test                              # Unit tests
rails test test:system                  # System tests
bin/rails db:test:prepare test test:system  # Full suite (CI)

# Linting & Security
bin/rubocop                             # Code style
bin/brakeman                            # Security scan
bin/importmap audit                     # JS dependency audit

# Database
rails db:reset db:fixtures:load         # Reset with sample data
```

## Architecture

### Dual Authentication System
- **Web interface:** Session-based via Devise (`authenticate_user!`)
- **API:** Bearer token authentication (`authenticate_with_token!` in `Api::BaseController`)

API requests require: `Authorization: Bearer <API_TOKEN>`

### Route Structure
```ruby
# Web (session auth)
resources :counters do
  member { post :increment }
end

# API (token auth)
namespace :api do
  resources :counters do
    member { post :increment }
  end
end
```

### Key Files
- `app/controllers/api/base_controller.rb` - API token validation
- `app/models/user.rb` - Devise auth + API token generation (`generate_api_token`, `regenerate_api_token!`)
- `app/models/counter.rb` - Counter with `increment!` method
- `lib/custom_failure_app.rb` - Devise JSON error responses
- `config/initializers/devise.rb` - Auth configuration

### Authorization Pattern
All resources are scoped to current user: `current_user.counters.find(...)` - never query counters directly without user scope.

### Response Conventions
- JSON: 201 for create, 204 for delete, 422 for validation errors
- HTML: Redirects with flash messages

## Testing

- Fixtures in `test/fixtures/` provide test data (3 users, 8 counters)
- Parallel test execution enabled
- System tests use Capybara + Selenium WebDriver

**Test Users (fixtures):**
- alice@example.com / password123 / alice_test_token_...
- bob@example.com / password123 / bob_test_token_...

## CI Pipeline

GitHub Actions runs: Brakeman security scan, ImportMap audit, RuboCop linting, full test suite.
