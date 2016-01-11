require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

require_relative './init.rb'
require 'discovery_service/application'

run DiscoveryService::Application
