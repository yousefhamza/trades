class Api::BaseController < ApplicationController
  skip_forgery_protection
  before_action :authenticate_with_token!

  private

  def current_user
    current_api_user
  end
end
