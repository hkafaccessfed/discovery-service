#!/usr/bin/env ruby

require_relative '../init.rb'
require 'discovery_service'

DiscoveryService::EventConsignment.new.perform
