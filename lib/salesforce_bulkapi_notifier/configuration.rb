module SalesforceBulkapiNotifier
  module Configuration

    VALID_CONFIG_KEYS = {
      slack_api_token: '',
      slack_channel_name: '',
      salesforce_host: '',
      salesforce_user_id: '',
      salesforce_password: '',
      salesforce_client_id: '',
      salesforce_client_secret: '',
      error_rate: 10,
      interval_seconds: 60,
      logger: nil,
      salesforce: nil,
      slack: nil,
    }.freeze
    attr_accessor(* VALID_CONFIG_KEYS.keys)

    def configure
      yield self
    end

    def self.extended(base)
      Dotenv.load

      raise 'Missing ENV[SLACK_API_TOKEN]!' unless ENV['SLACK_API_TOKEN']
      raise 'Missing ENV[SLACK_CHANNEL_NAME]!' unless ENV['SLACK_CHANNEL_NAME']
      raise 'Missing ENV[SALESFORCE_HOST]!' unless ENV['SALESFORCE_HOST']
      raise 'Missing ENV[SALESFORCE_USER_ID]!' unless ENV['SALESFORCE_USER_ID']
      raise 'Missing ENV[SALESFORCE_PASSWORD]!' unless ENV['SALESFORCE_PASSWORD']
      raise 'Missing ENV[SALESFORCE_CLIENT_ID]!' unless ENV['SALESFORCE_CLIENT_ID']
      raise 'Missing ENV[SALESFORCE_CLIENT_SECRET]!' unless ENV['SALESFORCE_CLIENT_SECRET']

      base.reset
    end

    def reset
      VALID_CONFIG_KEYS.each do |k, v|
        send((k.to_s + '='), v)
      end

      self.logger = ::Logger.new(STDOUT)
    end

    def setup
      self.salesforce = SalesforceService.new
      self.slack = SlackService.new
    end
  end
end
