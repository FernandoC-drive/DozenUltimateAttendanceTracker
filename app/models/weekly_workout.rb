class WeeklyWorkout < ApplicationRecord
  belongs_to :player, class_name: 'User'
end