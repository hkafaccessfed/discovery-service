require 'active_support/core_ext/hash'

RSpec.shared_context 'build_entity_data' do
  def build_entity_data(tags = nil)
    {
      entity_id: Faker::Internet.url,
      discovery_response: Faker::Internet.url,
      name: Faker::Company.name,
      tags: tags.nil? ? [Faker::Lorem.word, Faker::Lorem.word] : tags
    }
  end

  def to_hash(entities)
    hash = Hash[entities.map { |e| [e[:entity_id], e.except(:entity_id)] }]
    hash.each { |_k, v| v.symbolize_keys! }
  end
end
