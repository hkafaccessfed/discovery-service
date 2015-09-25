# TODO: Will be extended when filtering is implemented on the IdP selection page
RSpec.describe 'selecting an IdP', type: :feature do
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

    let(:idp_1) { build_entity_data(['discovery', 'idp', group_name, 'vho']) }
    let(:idp_2) { build_entity_data(['discovery', 'idp', group_name, 'vho']) }

    before { redis.set("entities:#{group_name}", [idp_1, idp_2].to_json) }

    it 'shows the page title' do
      visit path_for_group
      expect(page).to have_title 'AAF Discovery Service'
    end

    it 'shows the IdPs' do
      visit path_for_group
      expect(page).to have_content 'Select your IdP:'
      expect(page).to have_content idp_1[:name]
      expect(page).to have_content idp_2[:name]
    end
  end
end
