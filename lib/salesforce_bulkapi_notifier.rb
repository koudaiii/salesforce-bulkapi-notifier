require_relative 'salesforce_bulkapi_notifier/version'
require_relative 'salesforce_bulkapi_notifier/configuration'
require_relative 'salesforce_bulkapi_notifier/salesforce_service'
require_relative 'salesforce_bulkapi_notifier/slack_service'

require 'logger'
require 'slack-ruby-client'
require 'faraday'
require 'faraday_middleware'
require 'httpclient'
require 'dotenv'

module SalesforceBulkapiNotifier
  extend Configuration
  class << self
    if ENV['DOCKER_LOGS']
      $stdout = IO.new(IO.sysopen("/proc/1/fd/1", "w"),"w")
      $stdout.sync = true
      STDOUT = $stdout

      $stderr = IO.new(IO.sysopen("/proc/1/fd/1", "w"),"w")
      $stderr.sync = true
      STDERR = $stderr
    end

    Signal.trap(:INT) do
      puts 'Stopping salesforce bulkapi notifier'
      exit 0
    end

    Signal.trap('TERM') do
      puts 'Stopping salesforce bulkapi notifier'
      exit 0
    end

    def execute
      setup

      logger.info('Starting salesforce bulkapi notifier')
      logger.info("Version: #{SalesforceBulkapiNotifier::VERSION}")

      loop do
        jobs = salesforce.get_all_jobs
        logger.debug("All Job Count: #{jobs.size}")
        started_at = Time.now.utc.to_datetime - interval_seconds.second
        logger.debug("Screening by time: #{started_at}")
        target_jobs = salesforce.screening_by_time(jobs, started_at)
        logger.debug("Target Job Count: #{target_jobs.size}")

        target_jobs.each do |job|
          job_info = salesforce.get_job_info(job['id'])
          logger.debug("Job Infomation: #{job_info}")
          job_status = salesforce.annotate(job_info)
          logger.debug("Job Status: #{job_status}")
          next if job_status[:success]

          logger.info(job_status)
          logger.info(job_info)
          slack.notify(slack_channel_name, "Job created by #{job_status[:user_name]} using bulkapi failed due to '#{job_status[:message]}'.\nPlease check #{salesforce.instance_url}/#{job_info['id']}")
        end
        sleep interval_seconds.second
      end
    rescue => e
      logger.fatal(e)
    end
  end
end
