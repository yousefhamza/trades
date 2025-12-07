require "net/http"
require "json"

class SlackService
  SLACK_API_URL = "https://slack.com/api/chat.postMessage".freeze

  def initialize
    @bot_token = ENV["SLACK_BOT_TOKEN"]
    @channel_id = ENV["SLACK_CHANNEL_ID"]
  end

  def notify_increment(counter)
    puts "configured? #{configured?}"
    return unless configured?

    message = format_message(counter)
    send_message(message)
    puts "message sent"
  rescue StandardError => e
    Rails.logger.error("[SlackService] Failed to send notification: #{e.message}")
  end

  def configured?
    @bot_token.present? && @channel_id.present?
  end

  private

  def format_message(counter)
    "Counter *#{counter.name}* was incremented to *#{counter.count}*"
  end

  def send_message(text)
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
    request.body = { channel: @channel_id, text: text }.to_json

    response = http.request(request)
    body = JSON.parse(response.body)

    unless body["ok"]
      Rails.logger.error("[SlackService] Slack API error: #{body["error"]}")
    end

    body["ok"]
  end
end
