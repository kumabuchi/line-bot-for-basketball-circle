class Participation < ActiveRecord::Base
  scope :in_schedule,       ->(id) { where(schedule_id: id) }
  scope :participant,       -> { where(propriety: 1) }
  scope :order_by_id,       -> { order('user_id') }
  scope :group_by_schedule, -> { group('schedule_id') }

  def self.convert_propriety(propriety_str)
    case propriety_str
      when 'ko' then -1
      when 'un' then 0
      when 'ok' then 1
    end
  end
end
