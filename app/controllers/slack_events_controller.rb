class SlackEventsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    case params[:type]
    when "url_verification"
      # Slack sends this challenge when setting up the Events URL
      render json: { challenge: params[:challenge] }
    when "event_callback"
      handle_event(params[:event])
      head :ok
    else
      head :ok
    end
  end

  private

  def handle_event(event)
    case event[:type]
    when "tokens_revoked"
      handle_tokens_revoked(event)
    end
  end

  def handle_tokens_revoked(event)
    # event[:tokens][:oauth] contains array of user IDs whose tokens were revoked
    user_ids = event.dig(:tokens, :oauth) || []

    user_ids.each do |slack_user_id|
      user = User.find_by(slack_user_id: slack_user_id)
      if user
        user.disconnect_slack!
        Rails.logger.info("[SlackEvents] Disconnected Slack for user #{user.id} (#{user.email}) - token revoked")
      end
    end
  end
end
