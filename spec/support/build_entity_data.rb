RSpec.shared_context 'build_entity_data' do
  def build_entity_data(tags)
    {
      entity_id: Faker::Internet.url,
      sso_endpoint: Faker::Internet.url,
      name: Faker::Company.name,
      tags: tags
    }
  end
end
