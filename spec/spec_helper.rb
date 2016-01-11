require 'bundler/setup'
require 'simplecov'
require 'capybara/rspec'
require 'webmock/rspec'

ENV['RACK_ENV'] = 'test'
Bundler.require(:test)
Dir['./spec/support/*.rb'].each { |f| require f }

require_relative '../init.rb'

require 'fakeredis/rspec'

require 'discovery_service/application'
Capybara.app = DiscoveryService::Application

I18n.config.enforce_available_locales = true
I18n.config.default_locale = :en

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
end
