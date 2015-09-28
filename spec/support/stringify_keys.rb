RSpec.shared_context 'stringify_keys' do
  def stringify_keys(hash)
    Hash[hash.map{|(k,v)| [k.to_sym,v]}]
  end
end
