class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  respond_to :html, :json

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def record_not_found
    respond_to do |format|
      format.html { redirect_to root_path, alert: "Record not found." }
      format.json { render json: { error: "Not found" }, status: :not_found }
    end
  end

  def authenticate_with_token!
    token = extract_token_from_header
    @current_api_user = User.find_by(api_token: token) if token

    unless @current_api_user
      render json: { error: "Invalid or missing API token" }, status: :unauthorized
    end
  end

  def extract_token_from_header
    header = request.headers["Authorization"]
    header&.match(/^Bearer (.+)$/)&.[](1)
  end

  def current_api_user
    @current_api_user
  end
end
