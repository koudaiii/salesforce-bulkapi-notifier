# salesforce-bulkapi-notifier

[![Docker Repository on Quay](https://quay.io/repository/koudaiii/salesforce-bulkapi-notifier/status "Docker Repository on Quay")](https://quay.io/repository/koudaiii/salesforce-bulkapi-notifier)
[![Gem Version](https://badge.fury.io/rb/salesforce-bulkapi-notifier.svg)](https://badge.fury.io/rb/salesforce-bulkapi-notifier)

## Description
salesforce-bulkapi-notifier notify to slack when failed jobs. e.g. When job state is Failed or Error is higher than Error rate.

## Table of Contents

- [salesforce-bulkapi-notifier](#salesforce-bulkapi-notifier)
  - [Description](#description)
  - [Table of Contents](#table-of-contents)
  - [Requirements](#requirements)
  - [Installation](#installation)
    - [Run in a Docker container](#run-in-a-docker-container)
  - [Usage](#usage)
  - [Options](#options)
  - [Development](#development)
  - [Contribution](#contribution)
  - [Author](#author)
  - [License](#license)
  - [Code of Conduct](#code-of-conduct)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc.go)

## Requirements

- Ruby 2.7 or later
- Set enviroments
  - this tool run using [OAuth username password flow](https://help.salesforce.com/articleView?id=remoteaccess_oauth_username_password_flow.htm&type=5)
  - Slack API Token
    - To integrate your bot with Slack, you must first create a new [Slack App](https://api.slack.com/apps).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'salesforce-bulkapi-notifier'
```

And then execute:

```console
$ bundle
```

Or install it yourself as:

```console
$ gem install salesforce-bulkapi-notifier
```

### Run in a Docker container

TBD

## Usage

Please check [example code](./example)

```ruby
require 'salesforce-bulkapi-notifier'

SalesforceBulkAPINotifier.configure do |c|
  c.slack_api_token = ENV['SLACK_API_TOKEN'] # e.g. xxx-your-token-here
  c.slack_channel_name = ENV['SLACK_CHANNEL_NAME'] # Supported multi channel by using `,`. e,g #general,@kou
  c.salesforce_host = ENV['SALESFORCE_HOST'] # e.g. example.com
  c.salesforce_user_id = ENV['SALESFORCE_USER_ID'] # e.g. your@example.com
  c.salesforce_password = ENV['SALESFORCE_PASSWORD'] # e.g. your-password
  c.salesforce_client_id = ENV['SALESFORCE_CLIENT_ID'] # e.g. your-client-id
  c.salesforce_client_secret = ENV['SALESFORCE_CLIENT_SECRET'] # e.g. your-client-secret
end

SalesforceBulkAPINotifier.execute
```

## Options

- `error_rate` # default 10
- `interval_seconds` # default 60
- `logger.level` # default debug

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contribution

Bug reports and pull requests are welcome on GitHub at https://github.com/koudaiii/salesforce-bulkapi-notifier. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

1. Fork ([https://github.com/koudaiii/salesforce-bulkapi-notifier/fork](https://github.com/koudaiii/salesforce-bulkapi-notifier/fork))
1. Create a feature branch
1. Commit your changes
1. Rebase your local changes against the master branch
1. Run test suite with the `bundle exec rspec` command and confirm that it passes
1. Create a new Pull Request

## Author

[koudaiii](https://github.com/koudaiii)

## License

The gem is available as open source under the terms of the [![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

## Code of Conduct

Everyone interacting in the Salesforce-bulkapi-notifier project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/koudaiii/salesforce-bulkapi-notifier/blob/master/CODE_OF_CONDUCT.md).
