class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def disconnect_slack
    current_user.disconnect_slack!
    redirect_to settings_path, notice: "Slack account disconnected."
  end
end
