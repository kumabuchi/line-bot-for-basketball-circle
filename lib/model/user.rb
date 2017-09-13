class User < ActiveRecord::Base
  scope :need_remind,  -> { where remind: true }
  scope :need_request, -> { where request: true }

  def self.generate_random(length)
    o = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten
    (0...length).map { o[rand(o.length)] }.join 
  end

  def remind_display_value
    self.remind ? "ON" : "OFF"
  end

  def request_display_value
    self.request ? "ON" : "OFF"
  end
end
