require 'bundler/setup'
require 'simplecov'

ENV['RACK_ENV'] = 'test'

Bundler.require(:test)

require_relative '../init.rb'

RSpec.configure do |_config|
end
