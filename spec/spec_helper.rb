require 'bundler/setup'
require 'simplecov'
require 'capybara/rspec'
require 'webmock/rspec'

ENV['RACK_ENV'] = 'test'

Bundler.require(:test)

require_relative '../init.rb'
require 'discovery_service/application'

Capybara.app = DiscoveryService::Application

$stderr.reopen('log/rspec.log', 'w')

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
end
