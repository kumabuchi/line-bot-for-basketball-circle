require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

class GoogleCalendar

  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'linebot'
  CLIENT_SECRETS_PATH = "#{ROOT_DIR}/config/secret.json"
  CREDENTIALS_PATH = "#{ROOT_DIR}/config/google-calendar.yaml"
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR
  CALENDAR_ID = 'primary'

  def list(max_results = 100)
    service = initialize_service
    response = service.list_events(
      CALENDAR_ID,
      max_results: max_results,
      single_events: true,
      order_by: 'startTime',
      time_min: Time.now.iso8601
    )
    response.items
  end

  def create(summary, start_datetime, end_datetime)
    service = initialize_service
    event = create_event(summary, start_datetime, end_datetime)
    service.insert_event(CALENDAR_ID, event)
  end

  def add_reservation(msg)
    summary = nil
    start_datetime = nil
    end_datetime = nil
    responses = []

    msg.each_line do |line|
      line.strip!
      if line.include?('市民体育館')
        summary = line[0, 2] + '・'
        if line.include?('全面') || (line.include?('塩浜') && line.include?('１／２面'))
          summary << '全面'
        else
          summary << '片面' + line[line.length-1].tr('Ａ-Ｚ', 'A-Z')
        end
      end
      if /^利用日時/ =~ line
        datetimes = line.strip.split
        times = datetimes[2].split('～')
        start_datetime = DateTime.strptime(datetimes[1]+' '+times[0],'%Y/%m/%d %R') - Rational(9, 24)
        end_datetime   = DateTime.strptime(datetimes[1]+' '+times[1],'%Y/%m/%d %R') - Rational(9, 24)
      end
      if /^施設使用料/ =~ line
        responses.push(create(summary, start_datetime, end_datetime)) unless summary.nil? || start_datetime.nil? || end_datetime.nil?
        summary = nil
        start_datetime = nil
        end_datetime = nil
      end
    end
    responses
  end

  private

  def authorize
    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
 
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      code = ENV['GOOGLE_CALENDAR_ACCESS_CODE']
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

  def initialize_service
    service = Google::Apis::CalendarV3::CalendarService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize
    service
  end  

  def create_event(summary, start_datetime, end_datetime)
    # see https://developers.google.com/google-apps/calendar/create-events
    Google::Apis::CalendarV3::Event.new(
      summary: summary,
      location: '',
      description: '',
      start: {
        date_time: start_datetime.to_s,
        time_zone: 'Asia/Tokyo'
      },
      end: {
        date_time: end_datetime.to_s,
        time_zone: 'Asia/Tokyo'
      },
      recurrence: [
      ],
      attendees: [
      ],
      reminders: {
      }
    )
  end
end
