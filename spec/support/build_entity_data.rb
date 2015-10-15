require 'active_support/core_ext/hash'

RSpec.shared_context 'build_entity_data' do
  def build_entity_data(tags)
    {
      entity_id: Faker::Internet.url,
      discovery_response: Faker::Internet.url,
      name: Faker::Company.name,
      tags: tags
    }
  end

  def to_hash(entities)
    Hash[entities.map { |e| [e[:entity_id], e.except(:entity_id)] }]
  end
end
