class Api
  @@logger = Logger.new('log/sinatra.log')

  ACCESS_LOG          = 'access log'
  APPLICATION_LOG     = 'application log'
  ACTIVE_USERS        = 'active user'
  EXECUTION_RATE      = 'execution rate'
  PARTICIPATIONS_MEAN = 'participations mean'
  ACCESS_TRANSITION   = 'access transition'

  def search
    [ ACCESS_LOG, APPLICATION_LOG, ACTIVE_USERS, EXECUTION_RATE, PARTICIPATIONS_MEAN, ACCESS_TRANSITION ]
  end

  def query(params)
    from = DateTime.strptime(params[:range][:from].split('.')[0], '%Y-%m-%dT%H:%M:%S')
    to   = DateTime.strptime(params[:range][:to].split('.')[0],   '%Y-%m-%dT%H:%M:%S')

    response = []
    params[:targets].each do |target|
      target_metrics = case target[:target]
                       when ACCESS_LOG           then grep_unicorn_log(from, to)
                       when APPLICATION_LOG      then grep_sinatra_log(from, to)
                       when ACTIVE_USERS         then active_users
                       when EXECUTION_RATE       then execution_rate
                       when PARTICIPATIONS_MEAN  then participations_mean
                       when ACCESS_TRANSITION    then access_transition
                       else { target: target[:target], datapoints: [] }
                       end
      response.push(target_metrics)
    end
    response
  rescue => e
    @@logger.error("#{e.message}")
    []
  end

  private

  def mask(str)
    masked = str.gsub(/schedule\/[a-zA-Z0-9]{50}/, 'schedule/<<MASKED>>')
    masked = masked.gsub(/"random_hash"=>"[a-zA-Z0-9]{50}"/, '"random_hash"=>"<<MASKED>>"')
    masked.gsub(/"captures"=>\["[a-zA-Z0-9]{50}"\]/, '"captures"=>["<<MASKED>>"]')
  end

  def grep_unicorn_log(from, to)
    metrics = []
    log_raw = `awk -F [ '"#{from.strftime('%d/%b/%Y:%H:%M:%S')}" < $2 && $2 <= "#{to.strftime('%d/%b/%Y:%H:%M:%S')}"' #{ROOT_DIR}/log/unicorn.stderr.log | grep -v api`
    log_raw.each_line do |line|
      timestr = line.scan(/[0-9]{2}\/[a-zA-Z]{3}\/[0-9]{4}:[0-9]{2}:[0-9]{2}:[0-9]{2}/)
      metrics.push([mask(line), timestr[0]]) unless timestr.empty?
    end
    { target: ACCESS_LOG, datapoints: metrics }
  end

  def grep_sinatra_log(from, to)
    metrics = []
    log_raw = `awk -F [ '"#{from.strftime('%Y-%m-%dT%H:%M:%S')}" < $2 && $2 <= "#{to.strftime('%Y-%m-%dT%H:%M:%S')}"' #{ROOT_DIR}/log/sinatra.log`
    log_raw.each_line do |line|
      timestr = line.scan(/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{6}/)
      metrics.push([mask(line), timestr[0]]) unless timestr.empty?
    end
    { target: APPLICATION_LOG, datapoints: metrics }
  end

  def active_users
    { target: ACTIVE_USERS, datapoints: [ [User.count, DateTime.now] ] }
  end

  def execution_rate
    past_total         = Schedule.last_three_months.not_personal_practice.not_foo_fighters_practice.count
    past_not_cancelled = Schedule.last_three_months.not_personal_practice.not_foo_fighters_practice.not_like_cancelled.count
    { target: EXECUTION_RATE, datapoints: [ [past_not_cancelled.to_f/past_total.to_f * 100.0, DateTime.now] ] }
  end

  def participations_mean
    ok_counter = 0
    zero_schedule_counter = 0
    past_schedules = Schedule.last_three_months.not_personal_practice.not_foo_fighters_practice.not_like_cancelled
    past_schedules.each do |schedule|
      ok_counter += schedule.count_ok
      zero_schedule_counter += 1 if schedule.count_ok == 0
    end
    { target: PARTICIPATIONS_MEAN, datapoints: [ [ok_counter.to_f/(past_schedules.count-zero_schedule_counter).to_f, DateTime.now] ] }
  end

  def access_transition
    metrics = []
    log_raw = `cat #{ROOT_DIR}/log/unicorn.stderr.log | grep -P -o '\\d{2}/#{DateTime.now.strftime('%b/%Y')}' | sort | uniq -c`
    log_raw.each_line do |line|
      log_el = line.strip.split
      date = DateTime.strptime(log_el[1], '%d/%b/%Y')
      metrics.push([log_el[0].to_i, date.to_time.to_i*1000])
    end
    { target: ACCESS_TRANSITION, datapoints: metrics }
  end
end
