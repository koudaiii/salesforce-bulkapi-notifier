
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "salesforce_bulkapi_notifier/version"

Gem::Specification.new do |spec|
  spec.name          = "salesforce-bulkapi-notifier"
  spec.version       = SalesforceBulkAPINotifier::VERSION
  spec.authors       = ["koudaiii"]
  spec.email         = ["cs006061@gmail.com"]

  spec.summary       = %q{salesforce-bulkapi-notifier notify to slack}
  spec.description   = %q{salesforce-bulkapi-notifier notify to slack when failed jobs. e.g. When job state is Failed or Error is higher than Error rate.}
  spec.homepage      = "https://github.com/koudaiii/salesforce-bulkapi-notifier"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = " Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'faraday'
  spec.add_dependency 'faraday_middleware'
  spec.add_dependency 'httpclient'
  spec.add_dependency 'slack-ruby-client'
  spec.add_dependency 'dotenv'

  spec.add_development_dependency "pry"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
