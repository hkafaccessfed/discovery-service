require 'discovery_service'

RSpec.describe DiscoveryService::EventConsignment do
  describe '#perform' do
    let(:client) { double }
    let(:sqs_hostname) { "sqs.#{Faker::Internet.domain_name}" }
    let(:queue_name) { Faker::Lorem.words.join('-') }
    let(:client_opts) { { endpoint: app_config[:sqs][:endpoint] } }
    let(:redis) { Redis::Namespace.new(:discovery_service, redis: Redis.new) }
    let(:app_config) { base_app_config }
    let(:rsa_key_file) { 'spec/encryption_key.pem' }
    let(:rsa_key) { OpenSSL::PKey::RSA.new(File.read(rsa_key_file)) }

    let(:base_app_config) do
      {
        sqs: {
          queue_url: queue_url,
          endpoint: Faker::Internet.url,
          encryption_key: rsa_key_file
        }
      }
    end

    let(:queue_url) do
      Faker::Internet.url(sqs_hostname, "/queue/#{queue_name}")
    end

    before do
      allow(Aws::SQS::Client).to receive(:new).with(client_opts)
        .and_return(client)

      allow(DiscoveryService).to receive(:configuration).and_return(app_config)

      Redis::Connection::Memory.reset_all_databases
    end

    def run
      described_class.new.perform
    end

    context 'when using a stand-in SQS' do
      let(:app_config) { base_app_config.deep_merge(sqs: { fake: true }) }

      it 'creates the queue' do
        expect(client).to receive(:create_queue).with(queue_name: queue_name)
        run
      end
    end

    context 'with no waiting items' do
      it 'sends no messages' do
        run
      end
    end

    context 'with a waiting item' do
      let(:message) do
        { Faker::Lorem.word => Faker::Lorem.sentence }
      end

      before { redis.lpush('audit', JSON.generate(message)) }

      it 'sends the item to SQS' do
        args = { queue_url: queue_url, message_body: anything }
        expect(client).to receive(:send_message).with(args) do |opts|
          data = JSON::JWT.decode(opts[:message_body], rsa_key)
          expect(data['messages']).to contain_exactly(message)
        end

        run
      end

      it 'removes the item from the queue' do
        allow(client).to receive(:send_message).with(any_args)
        run

        expect(redis.llen('audit')).to be_zero
      end

      context 'when SQS fails' do
        it 'leaves the queue intact' do
          expect(client).to receive(:send_message).with(any_args) do
            fail('Nope')
          end

          expect { run }.to raise_error('Nope')
            .and not_change { redis.llen('audit') }
        end
      end
    end

    context 'with many waiting items' do
      let(:messages) do
        Array.new(20) { { Faker::Lorem.word => Faker::Lorem.sentence } }
      end

      before { messages.each { |m| redis.lpush('audit', JSON.generate(m)) } }

      it 'pushes the messages in batches of 10' do
        received = []

        args = { queue_url: queue_url, message_body: anything }
        expect(client).to receive(:send_message).with(args).twice do |opts|
          data = JSON::JWT.decode(opts[:message_body], rsa_key)
          expect(data['messages'].length).to eq(10)
          received += data['messages']
        end

        run

        expect(received).to contain_exactly(*messages)
      end

      it 'removes the items from the queue' do
        allow(client).to receive(:send_message).with(any_args)
        run

        expect(redis.llen('audit')).to be_zero
      end

      context 'when SQS fails' do
        it 'leaves the queue intact' do
          expect(client).to receive(:send_message).with(any_args) do
            fail('Nope')
          end

          expect { run }.to raise_error('Nope')
            .and not_change { redis.llen('audit') }
        end
      end
    end
  end
end
