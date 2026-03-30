class RecsportsEvent < ApplicationRecord
  has_many :participants,
           -> { order(:position, :last_name, :first_name) },
           class_name: "RecsportsEventParticipant",
           dependent: :destroy,
           inverse_of: :recsports_event

  validates :title, :source_url, :synced_at, presence: true

  scope :recent_first, -> { order(starts_at: :desc, created_at: :desc) }

  def event_date
    starts_at&.to_date
  end
end
