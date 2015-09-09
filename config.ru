require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

require_relative './init.rb'
require 'discovery_service/application'

app = Rack::Builder.new do
  run DiscoveryService::Application
end

run app
