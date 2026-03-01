class Attendance < ApplicationRecord
  belongs_to :player, class_name: 'User'


  validates :date, presence: true
  validates :date, uniqueness: { scope: :player_id, message: "has already been taken" }
  

  scope :for_day, ->(date) { where(date: date) }
  scope :for_week, ->(date) { where(date: date.beginning_of_week..date.end_of_week) }
  scope :for_month, ->(date) { where(date: date.beginning_of_month..date.end_of_month) }

  # Heatmap Logic: Scaled for ~12 meetings a month
  def heat_level
    # If they were absent on this specific day, the row gets no heat
    return 0 unless attended?

    # Count how many days the player attended in the month of this record
    monthly_total = Attendance.where(player_id: player_id, attended: true)
                              .for_month(date)
                              .count

    # Scale the color based on the 12 meetings/month metric
    case monthly_total
    when 1..4  then 1
    when 5..8  then 2
    when 9..11 then 3
    else            4
    end
  end
end