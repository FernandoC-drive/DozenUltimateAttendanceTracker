class RecsportsEventParticipant < ApplicationRecord
  belongs_to :recsports_event, inverse_of: :participants
  belongs_to :user

  validates :first_name, :last_name, presence: true
end
