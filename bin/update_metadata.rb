#!/usr/bin/env ruby

require_relative '../init'
require 'lib/discovery_service/metadata_updater'

DiscoveryService::MetadataUpdater.new.update
