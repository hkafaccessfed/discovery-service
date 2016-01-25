require 'aws-sdk'
require 'English'
require 'openssl'

module DiscoveryService
  # Consigns events to Amazon SQS for delivery to other services.
  class EventConsignment
    def initialize
      @sqs_config = DiscoveryService.configuration[:sqs]
      @identifier = SecureRandom.urlsafe_base64

      return unless @sqs_config[:fake]
      create_queue
    end

    def perform
      each_message_slice do |messages|
        claims = { 'iss' => 'discovery-service', 'messages' => messages }
        jwe = JSON::JWT.new(claims).encrypt(key)
        sqs_client.send_message(queue_url: queue_url, message_body: jwe.to_s)
      end
    end

    private

    def each_message_slice
      queued_messages.each_slice(10) do |messages|
        begin
          yield messages
        rescue
          requeue_messages
          raise
        end
      end
    end

    def requeue_messages
      nil while redis.rpoplpush("audit:#{@identifier}", 'audit')
    end

    def queued_messages
      Enumerator.new do |y|
        while (event = redis.rpoplpush('audit', "audit:#{@identifier}"))
          y << JSON.parse(event)
        end
      end
    end

    def queue_url
      @sqs_config[:queue_url]
    end

    def sqs_client
      @sqs_client ||= Aws::SQS::Client.new(endpoint: @sqs_config[:endpoint])
    end

    def redis
      @redis ||= Redis::Namespace.new(:discovery_service, redis: Redis.new)
    end

    def key
      @key ||= OpenSSL::PKey::RSA.new(File.read(@sqs_config[:encryption_key]))
    end

    def create_queue
      queue_name = queue_url.split('/').last
      sqs_client.create_queue(queue_name)
    end
  end
end
