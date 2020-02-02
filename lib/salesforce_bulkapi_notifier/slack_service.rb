module SalesforceBulkapiNotifier
  class SlackService
    def initialize
      Slack.configure do |config|
        config.token = SalesforceBulkapiNotifier.slack_api_token
      end
      @slack ||= Slack::Web::Client.new
      @slack.auth_test
    end

    def notify(channels, text)
      channels.split(',').each do |channel|
        @slack.chat_postMessage(channel: "#{channel}", text: "#{text}", as_user: true)
      end
    end
  end
end
