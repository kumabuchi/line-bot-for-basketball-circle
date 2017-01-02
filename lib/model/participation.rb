class Participation < ActiveRecord::Base
  scope :participant, -> { where(propriety: 1) }
  scope :in_schedule, ->(id) { where(schedule_id: id) }
  scope :order_by_id, -> { order("user_id") }
end
