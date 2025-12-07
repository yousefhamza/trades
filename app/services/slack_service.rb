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
    uri = URI(response_url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.cert_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = {
      replace_original: "true",
      text: "Counter #{counter.name} - Current count: #{counter.count}",
      blocks: build_blocks(counter)
    }.to_json

    response = http.request(request)
    body = JSON.parse(response.body)

    unless body["ok"]
      Rails.logger.error("[SlackService] Failed to update message: #{body["error"]}")
    end

    body["ok"]
  rescue StandardError => e
    Rails.logger.error("[SlackService] Failed to update message: #{e.message}")
    false
  end

  private

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
