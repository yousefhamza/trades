class Counter < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :count, numericality: { greater_than_or_equal_to: 0 }

  def increment!
    increment(:count)
    save!
  end
end
