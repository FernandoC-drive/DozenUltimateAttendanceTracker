class User < ApplicationRecord
  has_secure_password

  enum :role, { player: 0, coach: 1 }, default: :player

  has_many :attendances, foreign_key: :player_id, dependent: :destroy, inverse_of: :player
  has_many :workout_checkins, foreign_key: :player_id, dependent: :destroy, inverse_of: :player

  validates :name, :email, presence: true
  validates :email, uniqueness: true
end
