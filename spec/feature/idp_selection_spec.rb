# TODO: Will be extended when filtering is implemented on the IdP selection page
RSpec.describe 'selecting an idp', type: :feature do
  let(:redis) { Redis::Namespace.new(:discovery_service, redis: Redis.new) }
  let(:group_name) { Faker::Lorem.word }
  let(:path_for_group) { "/discovery/#{group_name}" }

  context 'when the group does not exist' do
    it 'returns http status code 404' do
      visit path_for_group
      expect(page.status_code).to eq(404)
    end
  end

  context 'when the group exists' do
    include_context 'build_entity_data'

    before { redis.set("pages:group:#{group_name}", 'Content here') }

    it 'shows the content' do
      visit path_for_group
      expect(page).to have_content 'Content here'
    end
  end
end
