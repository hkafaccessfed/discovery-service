# TODO: Will be extended when filtering is implemented on the IdP selection page
RSpec.describe 'selecting an IdP', type: :feature do
  let(:redis) { Redis::Namespace.new(:discovery_service, redis: Redis.new) }
  let(:entity_data) { nil }

  before do
    redis.set('entity_data', entity_data.to_json) if entity_data
    visit '/'
  end

  it 'shows the page title' do
    expect(page).to have_title 'AAF Discovery Service'
  end

  context 'when no IdPs exist' do
    # When the entity_data key has not been set in redis
    it 'shows there are none to display' do
      expect(page).to have_content 'No IdPs to display'
    end
  end

  context 'when IdPs exist' do
    include_context 'build_entity_data'
    let(:aaf_idp_1) { build_entity_data(%w(discovery idp aaf vho)) }
    let(:aaf_idp_2) { build_entity_data(%w(discovery idp aaf vho)) }
    let(:edugain_idp) { build_entity_data(%w(discovery idp edugain vho)) }

    let(:entity_data) do
      { aaf: [aaf_idp_1, aaf_idp_2],
        edugain: [edugain_idp] }
    end
    it 'shows them' do
      expect(page).to have_content 'Select your IdP:'
      expect(page).to have_content aaf_idp_1['name']
      expect(page).to have_content aaf_idp_2['name']
      expect(page).to have_content edugain_idp['name']
    end
  end
end
