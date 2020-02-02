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
      base.reset
    end

    def reset
      VALID_CONFIG_KEYS.each do |k, v|
        send((k.to_s + '='), v)
      end

      self.logger = ::Logger.new(STDOUT)
      logger.datetime_format = '%Y/%m/%dT%H:%M:%S.%06d'
    end

    def setup
      self.salesforce = SalesforceService.new
      self.slack = SlackService.new
    end
  end
end
