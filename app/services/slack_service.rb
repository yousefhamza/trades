require "net/http"
require "json"

class SlackService
  SLACK_API_URL = "https://slack.com/api/chat.postMessage".freeze

  def initialize
    @bot_token = ENV["SLACK_BOT_TOKEN"]
    @channel_id = ENV["SLACK_CHANNEL_ID"]
  end

  def share_counter(counter)
    unless configured?
      Rails.logger.error("[SlackService] Not configured. SLACK_BOT_TOKEN present: #{ENV['SLACK_BOT_TOKEN'].present?}, SLACK_CHANNEL_ID present: #{ENV['SLACK_CHANNEL_ID'].present?}")
      return false
    end

    send_message_with_blocks(counter)
  rescue StandardError => e
    Rails.logger.error("[SlackService] Failed to share counter: #{e.message}")
    Rails.logger.error(e.backtrace.first(5).join("\n"))
    false
  end

  def configured?
    @bot_token.present? && @channel_id.present?
  end

  def update_message(response_url, counter)
    post_to_response_url(response_url, {
      replace_original: "true",
      text: "Counter #{counter.name} - Current count: #{counter.count}",
      blocks: build_blocks(counter)
    })
  end

  def send_ephemeral(response_url, message)
    post_to_response_url(response_url, {
      response_type: "ephemeral",
      replace_original: false,
      text: message
    })
  end

  def send_ephemeral_with_connect_button(response_url, message)
    app_url = ENV["APP_URL"]
    unless app_url.present?
      Rails.logger.error("[SlackService] APP_URL environment variable is not set!")
      return send_ephemeral(response_url, "#{message} Please contact the administrator - OAuth is not configured.")
    end

    oauth_url = "#{app_url}/users/auth/slack_openid"

    post_to_response_url(response_url, {
      response_type: "ephemeral",
      replace_original: false,
      text: message,
      blocks: [
        {
          type: "section",
          text: { type: "mrkdwn", text: message }
        },
        {
          type: "actions",
          elements: [
            {
              type: "button",
              text: { type: "plain_text", text: "Connect Account" },
              url: oauth_url,
              style: "primary"
            }
          ]
        }
      ]
    })
  end

  private

  def post_to_response_url(response_url, payload)
    uri = URI(response_url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.cert_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    response = http.request(request)
    body = JSON.parse(response.body)

    unless body["ok"]
      Rails.logger.error("[SlackService] Failed to post to response_url: #{body["error"]}")
    end

    body["ok"]
  rescue StandardError => e
    Rails.logger.error("[SlackService] Failed to post to response_url: #{e.message}")
    false
  end

  def build_blocks(counter)
    [
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: "Counter *#{counter.name}* - Current count: *#{counter.count}*"
        }
      },
      {
        type: "actions",
        elements: [
          {
            type: "button",
            text: {
              type: "plain_text",
              text: "Increment",
              emoji: true
            },
            style: "primary",
            action_id: "increment_counter",
            value: counter.id.to_s
          }
        ]
      }
    ]
  end

  def send_message_with_blocks(counter)
    uri = URI(SLACK_API_URL)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.cert_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@bot_token}"
    request["Content-Type"] = "application/json"
    request.body = {
      channel: @channel_id,
      text: "Counter #{counter.name} - Current count: #{counter.count}",
      blocks: build_blocks(counter)
    }.to_json

    response = http.request(request)
    body = JSON.parse(response.body)

    unless body["ok"]
      Rails.logger.error("[SlackService] Slack API error: #{body["error"]}")
    end

    body["ok"]
  end
end
