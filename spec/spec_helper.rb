require 'bundler/setup'
require 'simplecov'
require 'capybara/rspec'

ENV['RACK_ENV'] = 'test'

Bundler.require(:test)

require_relative '../init.rb'
require 'discovery_service/application'

Capybara.app = DiscoveryService::Application
