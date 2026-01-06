RSpec.shared_context 'FOLIO Edge API setup' do
  let(:okapi) { 'https://folio.example.com' }
  let(:tenant) { 'test_tenant' }
  let(:token) { 'test_token' }

  let(:default_headers) do
    {
      'X-Okapi-Tenant' => tenant,
      'x-okapi-token' => token,
      :accept => 'application/json',
    }
  end
end