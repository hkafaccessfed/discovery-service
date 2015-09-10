describe 'the IdP selection process', type: :feature do
  it 'shows the page title' do
    visit '/'
    expect(page).to have_title 'AAF Discovery Service'
  end

  it 'shows IdPs to select from' do
    visit '/'
    expect(page).to have_content 'IdP1'
    expect(page).to have_content 'IdP2'
  end
end
