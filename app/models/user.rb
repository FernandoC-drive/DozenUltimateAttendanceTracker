class User < ApplicationRecord
  has_secure_password

  #enum :role, { player: 0, coach: 1 }, default: :player

  has_many :attendances, foreign_key: :player_id, dependent: :destroy, inverse_of: :player
  has_many :workout_checkins, foreign_key: :player_id, dependent: :destroy, inverse_of: :player

  validates :name, :email, presence: true
  validates :email, uniqueness: true

  devise :omniauthable, omniauth_providers: [:google_oauth2]

  def self.from_google(email:, full_name:, uid:, avatar_url:)
    user = find_or_initialize_by(email: email)
    user.uid = uid
    user.avatar_url = avatar_url
    
    user.name = full_name 
    
    if user.new_record?
      user.password = SecureRandom.hex(15)
    end
    
    user.save!
    user
  end
end
