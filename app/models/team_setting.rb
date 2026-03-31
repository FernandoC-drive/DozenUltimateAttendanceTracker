class TeamSetting < ApplicationRecord
  serialize :practice_days, type: Array, coder: JSON

  def self.current
    first_or_create!(practice_days: [1, 3, 5])
  end

  def practice_days_ints
    Array(practice_days).compact_blank.map(&:to_i)
  end
end