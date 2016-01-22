#!/usr/bin/env ruby

require_relative '../init'
require 'discovery_service'

DiscoveryService::Metadata::Updater.new.update
