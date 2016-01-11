#!/usr/bin/env ruby

require_relative '../init'
require 'discovery_service/metadata/updater'

DiscoveryService::Metadata::Updater.new.update
