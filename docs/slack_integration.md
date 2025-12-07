# Slack Integration

Share counters to Slack and increment them directly from Slack messages.

## Features

- **Share to Slack**: Click "Share to Slack" on any counter to post it to your Slack channel
- **Increment from Slack**: Click the "Increment" button in the Slack message to increase the count
- **Live Updates**: The Slack message updates in place to show the new count

## Slack App Setup

1. **Create a Slack App** at https://api.slack.com/apps

2. **Add OAuth Scopes** (OAuth & Permissions):
   - `chat:write` - to post messages to channels

3. **Enable Interactivity** (Interactivity & Shortcuts):
   - Toggle "Interactivity" to **On**
   - Set Request URL to: `https://<your-domain>/slack/interactions`

4. **Install the app** to your workspace

5. **Get your credentials**:
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
| `app/services/slack_service.rb` | Slack API communication |
| `config/routes.rb` | Defines `/slack/interactions` endpoint |

### Key Methods

**SlackService** (`app/services/slack_service.rb`):
- `share_counter(counter)` - Posts counter to Slack with interactive button
- `update_message(response_url, counter)` - Updates existing Slack message
- `build_blocks(counter)` - Builds Slack Block Kit message structure
- `configured?` - Checks if environment variables are set

**SlackInteractionsController** (`app/controllers/slack_interactions_controller.rb`):
- `create` - Entry point for all Slack interactions
- `handle_block_actions(payload)` - Routes button clicks
- `increment_counter(counter_id, response_url)` - Increments and updates message

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SLACK_BOT_TOKEN` | Bot token from Slack App (starts with `xoxb-`) |
| `SLACK_CHANNEL_ID` | Channel ID where messages are posted |

```bash
export SLACK_BOT_TOKEN=xoxb-your-bot-token
export SLACK_CHANNEL_ID=C0123456789
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

## Usage

1. Navigate to any counter in the web interface
2. Click "Share to Slack"
3. The counter appears in your Slack channel with an "Increment" button
4. Click "Increment" in Slack to increase the count - the message updates automatically
