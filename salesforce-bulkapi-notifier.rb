require 'faraday'
require 'faraday_middleware'
require 'httpclient'
require 'logger'
require 'dotenv'
require 'slack-ruby-client'

class SlackService
  def initialize
    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
    end
    @slack ||= Slack::Web::Client.new
    @slack.auth_test
  end

  def send(channels, text)
    channels.split(',').each do |channel|
      @slack.chat_postMessage(channel: "#{channel}", text: "#{text}", as_user: true)
    end
  end
end

class SalesforceService
  API_VERSION = 47.0
  attr_reader :instance_url

  def initialize
    con = Faraday.new(url: "https://#{ENV['SALESFORCE_HOST']}") do |c|
      c.adapter :httpclient
      c.request :json
    end

    # https://help.salesforce.com/articleView?id=remoteaccess_oauth_username_password_flow.htm&language=ja&type=0
    response = con.post("/services/oauth2/token", {
      grant_type: :password,
      username: ENV['SALESFORCE_USER_ID'],
      password: ENV['SALESFORCE_PASSWORD'],
      client_id: ENV['SALESFORCE_CLIENT_ID'],
      client_secret: ENV['SALESFORCE_CLIENT_SECRET'],
      format: :json,
    })

    data = JSON.parse(response.body)

    @access_token = data['access_token']
    @instance_url = data['instance_url']
  end

  def rest_api_client
    return nil unless @instance_url && @access_token
    @rest_api_client ||=
      Faraday.new(url: @instance_url) do |c|
        c.adapter :httpclient
        c.request :json
        c.headers['Authorization'] = "OAuth #{@access_token}"
        c.headers['Content-Type'] = 'application/json'
        c.headers['charset'] = 'UTF-8'
      end
  end

  # ref. https://developer.salesforce.com/docs/atlas.ja-jp.api_bulk_v2.meta/api_bulk_v2/get_all_jobs.htm
  def get_all_jobs
    res = rest_api_client.get("/services/data/v#{API_VERSION}/jobs/ingest")
    raise res if res.status != 200
    data = JSON.parse(res.body)
    jobs = data['records']
    done = data['done']

    until done
      res = rest_api_client.get(data['nextRecordsUrl'])
      raise res if res.status != 200
      data = JSON.parse(res.body)
      done = data['done']
      jobs += data['records']
    end
    jobs
  end

  # ref. https://developer.salesforce.com/docs/atlas.ja-jp.api_bulk_v2.meta/api_bulk_v2/get_job_info.htm
  def get_job_info(sf_job_id)
    res = rest_api_client.get("/services/data/v#{API_VERSION}/jobs/ingest/#{sf_job_id}")
    raise res if res.status != 200
    JSON.parse(res.body)
  end

  # ref. https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_sobject_user_password.htm
  def get_user_name(user_id)
    res = rest_api_client.get("/services/data/v#{API_VERSION}/sobjects/User/#{user_id}")
    raise res if res.status != 200
    JSON.parse(res.body)['Name']
  end

  def screening_by_time(jobs, started_at)
    jobs.map do |job|
      job if job['systemModstamp'].to_datetime >= started_at
    end.compact
  end

  def annotate(job_info)
    user_name = get_user_name(job_info['createdById'])
    error_rate = ((job_info['numberRecordsFailed'].to_f / job_info['numberRecordsProcessed'].to_f) * 100).floor(2)

    job_status = {success: true, message: "Success", error_rate: error_rate, user_name: user_name}
    if job_info['state'] == 'Failed'
      job_status[:success] = false
      job_status[:message] = "Job state is Failed"
    elsif error_rate >= ENV['ERROR_RATE'].to_i && job_info['state'] == "Closed"
      job_status[:success] = false
      job_status[:message] = "Error rate is #{error_rate}%. Error percentage is higher than #{ENV['ERROR_RATE']}%"
    else
    end
    job_status
  end
end

if ENV['DOCKER_LOGS']
  $stdout = IO.new(IO.sysopen("/proc/1/fd/1", "w"),"w")
  $stdout.sync = true
  STDOUT = $stdout

  $stderr = IO.new(IO.sysopen("/proc/1/fd/1", "w"),"w")
  $stderr.sync = true
  STDERR = $stderr
end

logger = Logger.new(STDOUT)
logger.datetime_format = '%Y/%m/%dT%H:%M:%S.%06d'
logger.info('Starting salesforce job watcher')

Signal.trap(:INT) do
  puts 'Stopping salesforce job watcher'
  exit 0
end

begin
  Dotenv.load

  raise 'Missing ENV[SLACK_API_TOKEN]!' unless ENV['SLACK_CHANNEL_NAME']
  raise 'Missing ENV[SLACK_CHANNEL_NAME]!' unless ENV['SLACK_CHANNEL_NAME']
  raise 'Missing ENV[SALESFORCE_HOST]!' unless ENV['SALESFORCE_HOST']
  raise 'Missing ENV[SALESFORCE_USER_ID]!' unless ENV['SALESFORCE_USER_ID']
  raise 'Missing ENV[SALESFORCE_PASSWORD]!' unless ENV['SALESFORCE_PASSWORD']
  raise 'Missing ENV[SALESFORCE_CLIENT_ID]!' unless ENV['SALESFORCE_CLIENT_ID']
  raise 'Missing ENV[SALESFORCE_CLIENT_SECRET]!' unless ENV['SALESFORCE_CLIENT_SECRET']
  raise 'Missing ENV[ERROR_RATE]!' unless ENV['ERROR_RATE']

  interval = if ENV['INTERVAL_SECONDS']
                ENV['INTERVAL_SECONDS'].to_i.second
              else
                60.second
              end

  salesforce = SalesforceService.new
  slack = SlackService.new

  loop do
    jobs = salesforce.get_all_jobs
    started_at = Time.now.utc.to_datetime - interval
    target_jobs = salesforce.screening_by_time(jobs, started_at)

    target_jobs.each do |job|
      job_info = salesforce.get_job_info(job['id'])
      job_status = salesforce.annotate(job_info)

      next if job_status[:success]

      logger.info(job_status)
      logger.info(job_info)
      slack.send(ENV['SLACK_CHANNEL_NAME'], "Job created by #{job_status[:user_name]} using bulkapi failed due to '#{job_status[:message]}'.\nPlease check #{salesforce.instance_url}/#{job_info['id']}")
    end
    sleep interval
  end
rescue => e
  logger.fatal(e)
end
