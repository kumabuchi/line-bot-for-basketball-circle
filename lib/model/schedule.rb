class Schedule < ActiveRecord::Base
  scope :in_future, -> { where("start >= ?", Date.today ) }
  scope :in_tomorrow, -> { where(start: Time.now.tomorrow.beginning_of_day..Time.now.tomorrow.end_of_day) }
  scope :in_week, -> { where(start: Time.now.tomorrow.beginning_of_day..(Time.now + 1.week).end_of_day) }
  scope :not_cancelled, -> { where is_cancelled: false }
  scope :not_personal_practice, -> { where.not('description like ?', '%信開%') }
  scope :order_by_start, -> { order("start DESC") }

  def date_ja(require_new_line = false)
    start_local = self.start.in_time_zone("Asia/Tokyo")
    end_local   = self.end.in_time_zone("Asia/Tokyo")
    date_str = nil
    if start_local.strftime('%m%d %H:%M:%S') == end_local.strftime('%m%d %H:%M:%S')
      # 終日のイベント
      date_str = start_local.strftime('%-m月%-d日(%a)')
    elsif start_local.strftime('%m%d') == end_local.strftime('%m%d')
      # 同日内のイベント
      date_str = start_local.strftime("%-m月%-d日(%a)%-H:%M") + '-' + end_local.strftime('%-H:%M')
    else
      # 数日に跨るイベント
      date_str = start_local.strftime("%-m月%-d日(%a)%-H:%M") + '-' + end_local.strftime("%-m月%-d日(%a)%-H:%M")
    end
    date_str = date_str.gsub(')', ")\n")
    convert_week(date_str)
  end

  def convert_week(date_str)
    date_str.gsub!('Sun', '日')
    date_str.gsub!('Mon', '月')
    date_str.gsub!('Tue', '火')
    date_str.gsub!('Wed', '水')
    date_str.gsub!('Thu', '木')
    date_str.gsub!('Fri', '金')
    date_str.gsub!('Sat', '土')
    date_str
  end

  def count_ok
    Participation.where(schedule_id: self.id).where(propriety: 1).count
  end

  def count_un
    Participation.where(schedule_id: self.id).where(propriety: 0).count
  end
end
