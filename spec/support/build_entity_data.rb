require 'active_support/core_ext/hash'

RSpec.shared_context 'build_entity_data' do
  def build_entity_data(tags = nil, lang = nil)
    {
      entity_id: Faker::Internet.url,
      discovery_response: Faker::Internet.url,
      names: [{ value: Faker::University.name,
                lang: lang ? lang : Faker::Lorem.characters(2) }],
      tags: tags.nil? ? [Faker::Lorem.word, Faker::Lorem.word] : tags
    }
  end

  def to_hash(entities)
    Hash[entities.map { |e| [e[:entity_id], e.except(:entity_id)] }]
  end
end
