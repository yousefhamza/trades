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
    slack_user_id = payload.dig("user", "id")

    payload["actions"].each do |action|
      case action["action_id"]
      when "increment_counter"
        increment_counter(action["value"], response_url, slack_user_id)
      end
    end

    head :ok
  end

  def increment_counter(counter_id, response_url, slack_user_id)
    counter = Counter.find_by(id: counter_id)
    return unless counter

    # Find user by Slack ID
    slack_user = User.find_by(slack_user_id: slack_user_id)

    # Case 1: Slack user not linked to any account
    unless slack_user
      SlackService.new.send_ephemeral_with_connect_button(
        response_url,
        "Your Slack account is not linked to a Trades account."
      )
      return
    end

    # Case 2: Slack user is not the counter owner
    unless counter.user_id == slack_user.id
      SlackService.new.send_ephemeral(
        response_url,
        "You are not authorized to increment this counter. Only the owner can increment it."
      )
      return
    end

    # Case 3: Authorized - increment and update message
    counter.increment!
    SlackService.new.update_message(response_url, counter)
    Rails.logger.info("[SlackInteractions] Counter #{counter.id} incremented via Slack by user #{slack_user.id} to #{counter.count}")
  end
end
