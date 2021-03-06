require 'active_support/core_ext/hash'

RSpec.shared_context 'build_entity_data' do
  def build_idp_data(tags = nil, lang = nil, name = nil)
    entity_data = build_entity_data(tags, lang, name)
    entity_data[:geolocations] = [{ longitude: Faker::Address.longitude,
                                    latitude: Faker::Address.latitude }]
    entity_data[:single_sign_on_endpoints] = { soap: [Faker::Internet.url] }
    entity_data
  end

  def build_sp_data(tags = nil, lang = nil)
    entity_data = build_entity_data(tags, lang)
    entity_data[:discovery_response] = Faker::Internet.url
    entity_data[:information_urls] = [{ url: Faker::Internet.url, lang: lang }]
    entity_data[:descriptions] = [{ value: Faker::Lorem.sentence, lang: lang }]
    entity_data[:privacy_statement_urls] =
      [{ url: Faker::Internet.url, lang: lang }]
    entity_data
  end

  def to_hash(entities)
    Hash[entities.map { |e| [e[:entity_id], e.except(:entity_id)] }]
  end

  def build_entity_data(tags = nil, specified_lang = nil, name = nil)
    lang = specified_lang ? specified_lang : Faker::Lorem.characters(2)
    {
      entity_id: Faker::Internet.url,
      names: [{ value: name ? name : Faker::University.name, lang: lang }],
      tags: tags.nil? ? [Faker::Lorem.word, Faker::Lorem.word] : tags,
      logos: [{ url: Faker::Company.logo, lang: lang }],
      domains: [Faker::Internet.domain_name]
    }
  end
end
