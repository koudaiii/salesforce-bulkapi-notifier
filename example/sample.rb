require 'dotenv'
require 'salesforce-bulkapi-notifier'

Dotenv.load

SalesforceBulkAPINotifier.configure do |c|
  c.slack_api_token = ENV['SLACK_API_TOKEN']
  c.slack_channel_name = ENV['SLACK_CHANNEL_NAME']
  c.salesforce_host = ENV['SALESFORCE_HOST']
  c.salesforce_user_id = ENV['SALESFORCE_USER_ID']
  c.salesforce_password = ENV['SALESFORCE_PASSWORD']
  c.salesforce_client_id = ENV['SALESFORCE_CLIENT_ID']
  c.salesforce_client_secret = ENV['SALESFORCE_CLIENT_SECRET']
  c.error_rate = ENV['ERROR_RATE'].to_i || 10
  c.interval_seconds = ENV['INTERVAL_SECONDS'].to_i || 60
  c.logger.level = :debug
end

SalesforceBulkAPINotifier.execute
