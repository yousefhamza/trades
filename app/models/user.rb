class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :slack_openid ]

  has_many :counters, dependent: :destroy

  before_create :generate_api_token

  def regenerate_api_token!
    generate_api_token
    save!
  end

  def slack_connected?
    slack_user_id.present?
  end

  def connect_slack!(auth_hash)
    # auth_hash.uid is formatted as "team_id-user_id", extract just the user_id
    uid_parts = auth_hash.uid.to_s.split("-")
    user_id = uid_parts.last  # The user ID (e.g., "U0A0WHKBA20")
    team_id = uid_parts.first # The team ID (e.g., "T0A1M9UHAE4")

    update!(
      slack_user_id: user_id,
      slack_team_id: team_id,
      slack_access_token: auth_hash.credentials.token
    )
  end

  def disconnect_slack!
    update!(slack_user_id: nil, slack_team_id: nil, slack_access_token: nil)
  end

  private

  def generate_api_token
    self.api_token = SecureRandom.hex(32)
  end
end
