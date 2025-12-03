# Trades

A Rails application for tracking counters. Each user can create and increment their own counters.

## Setup

```bash
# Install dependencies
bundle install

# Create and migrate database
rails db:create db:migrate
```

## Database Commands

### Load fixtures (sample data)

```bash
rails db:fixtures:load
```

This loads sample users and counters from `test/fixtures/`.

### Reset database and load fixtures

```bash
rails db:reset db:fixtures:load
```

Or to completely drop, recreate, migrate, and load fixtures:

```bash
rails db:drop db:create db:migrate db:fixtures:load
```

### Reset database only (empty)

```bash
rails db:reset
```

## Sample Users

After loading fixtures, these users are available:

| Email | Password | API Token |
|-------|----------|-----------|
| alice@example.com | password123 | `alice_test_token_1234567890abcdef1234567890abcdef` |
| bob@example.com | password123 | `bob_test_token_1234567890abcdef1234567890abcdef12` |
| charlie@example.com | password123 | `charlie_test_token_1234567890abcdef1234567890abcd` |

## Running the Server

```bash
rails server
```

Visit http://localhost:3000

## JSON API

The API uses **Bearer token authentication**. Include your API token in the `Authorization` header.

### Base URL

```
/api/counters
```

### Authentication

All API requests require a Bearer token in the Authorization header:

```bash
curl -H "Authorization: Bearer YOUR_API_TOKEN" http://localhost:3000/api/counters
```

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/counters` | List all user's counters |
| GET | `/api/counters/:id` | Show single counter |
| POST | `/api/counters` | Create counter |
| PATCH | `/api/counters/:id` | Update counter |
| DELETE | `/api/counters/:id` | Delete counter |
| POST | `/api/counters/:id/increment` | Increment counter |

### Examples

Using Alice's test token: `alice_test_token_1234567890abcdef1234567890abcdef`

#### List All Counters

```bash
curl -s http://localhost:3000/api/counters \
  -H "Authorization: Bearer alice_test_token_1234567890abcdef1234567890abcdef" | jq
```

Response:
```json
[
  {"id": 1, "name": "Daily Tasks", "count": 15, "user_id": 1, "created_at": "...", "updated_at": "..."},
  {"id": 2, "name": "Cups of Coffee", "count": 42, "user_id": 1, "created_at": "...", "updated_at": "..."}
]
```

#### Get Single Counter

```bash
curl -s http://localhost:3000/api/counters/1 \
  -H "Authorization: Bearer alice_test_token_1234567890abcdef1234567890abcdef" | jq
```

#### Create Counter

```bash
curl -s http://localhost:3000/api/counters \
  -X POST \
  -H "Authorization: Bearer alice_test_token_1234567890abcdef1234567890abcdef" \
  -H "Content-Type: application/json" \
  -d '{"counter": {"name": "New Counter"}}' | jq
```

Response:
```json
{"id": 4, "name": "New Counter", "count": 0, "user_id": 1, "created_at": "...", "updated_at": "..."}
```

#### Update Counter

```bash
curl -s http://localhost:3000/api/counters/1 \
  -X PATCH \
  -H "Authorization: Bearer alice_test_token_1234567890abcdef1234567890abcdef" \
  -H "Content-Type: application/json" \
  -d '{"counter": {"name": "Renamed Counter"}}' | jq
```

#### Increment Counter

```bash
curl -s http://localhost:3000/api/counters/1/increment \
  -X POST \
  -H "Authorization: Bearer alice_test_token_1234567890abcdef1234567890abcdef" | jq
```

Response:
```json
{"id": 1, "name": "Daily Tasks", "count": 16, "user_id": 1, "created_at": "...", "updated_at": "..."}
```

#### Delete Counter

```bash
curl -s http://localhost:3000/api/counters/1 \
  -X DELETE \
  -H "Authorization: Bearer alice_test_token_1234567890abcdef1234567890abcdef"
```

Response: `204 No Content`

### Error Responses

#### Invalid or Missing Token (401)

```json
{"error": "Invalid or missing API token"}
```

#### Not Found (404)

```json
{"error": "Not found"}
```

#### Validation Error (422)

```json
{"errors": {"name": ["can't be blank"]}}
```

### Quick Test Script

Save as `test_api.sh`:

```bash
#!/bin/bash
BASE=http://localhost:3000/api
TOKEN="alice_test_token_1234567890abcdef1234567890abcdef"
AUTH="Authorization: Bearer $TOKEN"

echo "=== List counters ==="
curl -s -H "$AUTH" "$BASE/counters" | jq

echo ""
echo "=== Create counter ==="
curl -s -X POST -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"counter": {"name": "API Test"}}' "$BASE/counters" | jq

echo ""
echo "=== Increment counter 1 ==="
curl -s -X POST -H "$AUTH" "$BASE/counters/1/increment" | jq

echo "Done!"
```

## Running Tests

```bash
rails test
```
