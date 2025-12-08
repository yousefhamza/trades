class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def slack_openid
    if current_user
      # User is logged in - link their Slack account
      current_user.connect_slack!(auth_hash)
      redirect_to settings_path, notice: "Slack account connected successfully!"
    else
      # User is not logged in - redirect to login
      redirect_to new_user_session_path, alert: "Please log in first to connect your Slack account."
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to settings_path, alert: "Failed to connect Slack: #{e.message}"
  end

  def failure
    Rails.logger.error("[OmniAuth] Slack auth failed: #{failure_message}")
    Rails.logger.error("[OmniAuth] Failure details: #{request.env['omniauth.error'].inspect}")
    redirect_to settings_path, alert: "Slack authentication failed: #{failure_message}"
  end

  private

  def auth_hash
    request.env["omniauth.auth"]
  end
end
