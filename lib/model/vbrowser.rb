require 'selenium-webdriver'

class Vbrowser

  def capture_reservation
    setup
    base_url = "http://www.city.ichikawa.lg.jp/"
    @driver.get("#{base_url}/sys03/1511000003.html")
    @driver.find_element(:css, 'img[alt="施設予約システムへ"]').click
    @driver.find_element(:id, "btnNormal").click
    @driver.find_element(:id, "btnNext").click
    @driver.find_element(:id, "rbtnKakunin").click
    @driver.find_element(:id, "txtID").clear
    @driver.find_element(:id, "txtID").send_keys Settings.reservation.id
    @driver.find_element(:id, "txtPass").clear
    @driver.find_element(:id, "txtPass").send_keys Settings.reservation.password
    @driver.find_element(:id, "ucPCFooter_btnForward").click
    60.times do  
      break if (@driver.find_element(:id, "btnKirikae").displayed? rescue false)
      sleep 1
    end
    @driver.find_element(:id, "btnKirikae").click
    @driver.find_element(:id, "btnPrint").click

    filename = "#{User.generate_random(50)}.png"
    @driver.save_screenshot("#{ROOT_DIR}/webroot/static/reservation/#{filename}")

    tear_down
    filename
  end

  private

  def setup
    @driver = Selenium::WebDriver.for :phantomjs
    @driver.manage.timeouts.implicit_wait = 30
  end

  def tear_down
    @driver.quit
  end
end

