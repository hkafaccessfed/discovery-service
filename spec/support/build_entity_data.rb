require 'active_support/core_ext/hash'

RSpec.shared_context 'build_entity_data' do
  def build_idp_data(tags = nil, lang = nil)
    entity_data = build_entity_data(tags, lang)
    entity_data[:geolocations] = [{ longitude: Faker::Address.longitude,
                                    latitude: Faker::Address.latitude }]
    entity_data
  end

  def build_sp_data(tags = nil, lang = nil)
    entity_data = build_entity_data(tags, lang)
    entity_data[:information_uri] = Faker::Internet.url
    entity_data[:privacy_statement_uri] = Faker::Internet.url
    entity_data
  end

  def to_hash(entities)
    Hash[entities.map { |e| [e[:entity_id], e.except(:entity_id)] }]
  end

  private

  def build_entity_data(tags = nil, lang = nil)
    {
      entity_id: Faker::Internet.url,
      discovery_response: Faker::Internet.url,
      names: [{ value: Faker::University.name,
                lang: lang ? lang : Faker::Lorem.characters(2) }],
      tags: tags.nil? ? [Faker::Lorem.word, Faker::Lorem.word] : tags,
      logo_uri: Faker::Company.logo,
      description: Faker::Lorem.sentence,
      domain: Faker::Internet.domain_name
    }
  end
end
