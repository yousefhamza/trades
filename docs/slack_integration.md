# Slack Integration

Share counters to Slack and increment them directly from Slack messages.

## Features

- **Share to Slack**: Click "Share to Slack" on any counter to post it to your Slack channel
- **Increment from Slack**: Click the "Increment" button in the Slack message to increase the count
- **Live Updates**: The Slack message updates in place to show the new count

## Slack App Setup

1. **Create a Slack App** at https://api.slack.com/apps

2. **Add OAuth Scopes** (OAuth & Permissions):
   - **Bot Token Scopes:**
     - `chat:write` - to post messages to channels
   - **User Token Scopes:**
     - `openid` - for OAuth authentication
     - `profile` - to get user profile info
   - **Redirect URLs:**
     - Add: `https://<your-domain>/users/auth/slack_openid/callback`

3. **Enable Interactivity** (Interactivity & Shortcuts):
   - Toggle "Interactivity" to **On**
   - Set Request URL to: `https://<your-domain>/slack/interactions`

4. **Enable Event Subscriptions** (Event Subscriptions):
   - Toggle "Enable Events" to **On**
   - Set Request URL to: `https://<your-domain>/slack/events`
   - Subscribe to bot events:
     - `tokens_revoked` - to handle when users revoke access

5. **Install the app** to your workspace

6. **Get your credentials** (Basic Information & OAuth & Permissions):
   - Client ID: Found in "Basic Information"
   - Client Secret: Found in "Basic Information"
   - Bot Token: Found in "OAuth & Permissions" (starts with `xoxb-`)
   - Channel ID: Right-click on a channel in Slack → "View channel details" → copy the ID at the bottom

## Code Flow

### Share to Slack Flow

```
User clicks "Share to Slack" button
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ CountersController#share_to_slack                       │
│ app/controllers/counters_controller.rb                  │
│                                                         │
│ - Authenticates user (Devise)                           │
│ - Finds counter scoped to current_user                  │
│ - Calls SlackService.new.share_counter(@counter)        │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ SlackService#share_counter(counter)                     │
│ app/services/slack_service.rb                           │
│                                                         │
│ - Checks if configured (SLACK_BOT_TOKEN, CHANNEL_ID)    │
│ - Builds message blocks with Block Kit (build_blocks)   │
│ - POSTs to Slack API: chat.postMessage                  │
│ - Message includes "Increment" button with counter ID   │
└─────────────────────────────────────────────────────────┘
         │
         ▼
   Message appears in Slack channel
```

### Increment from Slack Flow

```
User clicks "Increment" button in Slack
         │
         ▼
   Slack sends POST to /slack/interactions
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ SlackInteractionsController#create                      │
│ app/controllers/slack_interactions_controller.rb        │
│                                                         │
│ - Skips CSRF protection (Slack can't provide token)     │
│ - Parses JSON payload from params[:payload]             │
│ - Routes to handle_block_actions for button clicks      │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ SlackInteractionsController#increment_counter           │
│ (private method)                                        │
│                                                         │
│ - Extracts counter_id from action value                 │
│ - Extracts response_url from payload                    │
│ - Finds counter by ID                                   │
│ - Calls counter.increment!                              │
│ - Calls SlackService.new.update_message(response_url,   │
│         counter) to update the Slack message            │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ SlackService#update_message(response_url, counter)      │
│ app/services/slack_service.rb                           │
│                                                         │
│ - POSTs to response_url (Slack-provided signed URL)     │
│ - Sends replace_original: true to update in place       │
│ - Includes updated blocks with new count                │
└─────────────────────────────────────────────────────────┘
         │
         ▼
   Slack message updates with new count
```

### Key Files

| File | Purpose |
|------|---------|
| `app/controllers/counters_controller.rb` | `share_to_slack` action for web UI |
| `app/controllers/slack_interactions_controller.rb` | Handles Slack button callbacks |
| `app/controllers/slack_events_controller.rb` | Handles Slack events (token revocation) |
| `app/controllers/settings_controller.rb` | User settings for Slack connection |
| `app/controllers/users/omniauth_callbacks_controller.rb` | OAuth callback handler |
| `app/services/slack_service.rb` | Slack API communication |
| `config/routes.rb` | Defines `/slack/interactions` and `/slack/events` endpoints |

### Key Methods

**SlackService** (`app/services/slack_service.rb`):
- `share_counter(counter)` - Posts counter to Slack with interactive button
- `update_message(response_url, counter)` - Updates existing Slack message
- `send_ephemeral(response_url, message)` - Sends ephemeral message (only visible to one user)
- `send_ephemeral_with_connect_button(response_url, message)` - Ephemeral with OAuth button
- `build_blocks(counter)` - Builds Slack Block Kit message structure
- `configured?` - Checks if environment variables are set

**SlackInteractionsController** (`app/controllers/slack_interactions_controller.rb`):
- `create` - Entry point for all Slack interactions
- `handle_block_actions(payload)` - Routes button clicks
- `increment_counter(counter_id, response_url, slack_user_id)` - Verifies auth and increments

**SlackEventsController** (`app/controllers/slack_events_controller.rb`):
- `create` - Entry point for Slack events
- `handle_tokens_revoked(event)` - Disconnects users when they revoke access

**User** (`app/models/user.rb`):
- `connect_slack!(auth_hash)` - Links Slack account via OAuth
- `disconnect_slack!` - Removes Slack connection
- `slack_connected?` - Checks if Slack is linked

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SLACK_BOT_TOKEN` | Bot token from Slack App (starts with `xoxb-`) |
| `SLACK_CHANNEL_ID` | Channel ID where messages are posted |
| `SLACK_CLIENT_ID` | OAuth Client ID from Basic Information |
| `SLACK_CLIENT_SECRET` | OAuth Client Secret from Basic Information |
| `APP_URL` | Public URL of your app (ngrok URL for local dev) |

```bash
export SLACK_BOT_TOKEN=xoxb-your-bot-token
export SLACK_CHANNEL_ID=C0123456789
export SLACK_CLIENT_ID=1234567890.1234567890123
export SLACK_CLIENT_SECRET=abcdef1234567890
export APP_URL=https://your-ngrok-url.ngrok.io
```

## Local Development with ngrok

Slack needs a public URL to send interaction payloads. Use ngrok for local development:

```bash
# Terminal 1: Start Rails
rails server

# Terminal 2: Start ngrok
ngrok http 3000
```

Copy the ngrok HTTPS URL (e.g., `https://abc123.ngrok.io`) and set it as your Slack app's Interactivity Request URL:

```
https://abc123.ngrok.io/slack/interactions
```

Note: The ngrok URL changes each restart (unless on a paid plan), so update the Slack Request URL accordingly.

## Authentication

Only counter owners can increment their counters from Slack. Users must link their Slack account first.

### OAuth Flow (Detailed)

```
User clicks "Connect Slack" button
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ POST https://<your-domain>/users/auth/slack_openid                          │
│                                                                             │
│ OmniAuth initiates the OAuth flow                                           │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ Redirect to Slack Authorization URL:                                        │
│                                                                             │
│ https://slack.com/openid/connect/authorize                                  │
│   ?client_id=<SLACK_CLIENT_ID>                                              │
│   &redirect_uri=https://<your-domain>/users/auth/slack_openid/callback      │
│   &response_type=code                                                       │
│   &scope=openid,profile                                                     │
│   &state=<random_state_token>                                               │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
   User sees Slack authorization screen and approves
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ Slack redirects back to:                                                    │
│                                                                             │
│ GET https://<your-domain>/users/auth/slack_openid/callback                  │
│   ?code=<authorization_code>                                                │
│   &state=<random_state_token>                                               │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ Users::OmniauthCallbacksController#slack_openid                             │
│ app/controllers/users/omniauth_callbacks_controller.rb                      │
│                                                                             │
│ - OmniAuth exchanges code for access token (server-to-server)               │
│ - Extracts user ID and team ID from auth hash                               │
│ - Calls current_user.connect_slack!(auth_hash)                              │
│ - Redirects to /settings with success message                               │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ User#connect_slack!(auth_hash)                                              │
│ app/models/user.rb                                                          │
│                                                                             │
│ Stores in database:                                                         │
│ - slack_user_id (e.g., "U0A0WHKBA20")                                       │
│ - slack_team_id (e.g., "T0A1M9UHAE4")                                       │
│ - slack_access_token (for future API calls)                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

### URLs Reference

| Purpose | URL |
|---------|-----|
| Start OAuth | `POST https://<your-domain>/users/auth/slack_openid` |
| OAuth Callback | `GET https://<your-domain>/users/auth/slack_openid/callback` |
| Settings Page | `GET https://<your-domain>/settings` |
| Disconnect Slack | `DELETE https://<your-domain>/settings/disconnect_slack` |

### Slack App Redirect URL Configuration

In your Slack App (OAuth & Permissions → Redirect URLs), add:
```
https://<your-domain>/users/auth/slack_openid/callback
```

For local development with ngrok:
```
https://abc123.ngrok.io/users/auth/slack_openid/callback
```

### Linking Slack Account

1. Log into the web app
2. Go to `/settings`
3. Click "Connect Slack"
4. Authorize the app in Slack
5. Your Slack account is now linked

### Incrementing from Slack (Authorization Flow)

When a user clicks "Increment" in Slack:

1. **Not linked:** Shows ephemeral "Connect Account" button → starts OAuth
2. **Linked but not owner:** Shows ephemeral "Not authorized" message
3. **Owner:** Counter increments and message updates

### Token Revocation

When a user revokes access from Slack's side:

1. Slack sends `tokens_revoked` event to `/slack/events`
2. `SlackEventsController` receives the event
3. User's Slack connection is automatically removed from the database

## Usage

1. Navigate to any counter in the web interface
2. Click "Share to Slack"
3. The counter appears in your Slack channel with an "Increment" button
4. Click "Increment" in Slack to increase the count - the message updates automatically
5. Only the counter owner (with linked Slack account) can increment
