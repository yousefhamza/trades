class SlackInteractionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = JSON.parse(params[:payload])

    case payload["type"]
    when "block_actions"
      handle_block_actions(payload)
    else
      head :ok
    end
  end

  private

  def handle_block_actions(payload)
    response_url = payload["response_url"]

    payload["actions"].each do |action|
      case action["action_id"]
      when "increment_counter"
        increment_counter(action["value"], response_url)
      end
    end

    head :ok
  end

  def increment_counter(counter_id, response_url)
    counter = Counter.find_by(id: counter_id)
    return unless counter

    counter.increment!
    SlackService.new.update_message(response_url, counter)
    Rails.logger.info("[SlackInteractions] Counter #{counter.id} incremented via Slack to #{counter.count}")
  end
end
