class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :counters, dependent: :destroy

  before_create :generate_api_token

  def regenerate_api_token!
    generate_api_token
    save!
  end

  private

  def generate_api_token
    self.api_token = SecureRandom.hex(32)
  end
end
