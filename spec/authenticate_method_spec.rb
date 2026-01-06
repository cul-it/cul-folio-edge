require 'cul/folio/edge'
require 'rest-client'

describe CUL::FOLIO::Edge do
  describe '.authenticate' do
    let(:okapi) { 'https://folio.example.com' }
    let(:tenant) { 'test_tenant' }
    let(:username) { 'testuser' }
    let(:password) { 'secret' }
    let(:headers) do
      {
        'X-Okapi-Tenant' => tenant,
        :accept => 'application/json',
        'X-Forwarded-For' => 'Stripes',
        :content_type => 'application/json'
      }
    end
    let(:body) { { 'username' => username, 'password' => password }.to_json }

    context 'when method is :new' do
      it 'calls authenticate_new with correct arguments' do
        expect(described_class).to receive(:authenticate_new).with(okapi, headers, body).and_return(:result)
        result = described_class.authenticate(okapi, tenant, username, password, method: :new)
        expect(result).to eq(:result)
      end
    end

    context 'when method is :old' do
      it 'calls authenticate_old with correct arguments' do
        expect(described_class).to receive(:authenticate_old).with(okapi, headers, body).and_return(:old_result)
        result = described_class.authenticate(okapi, tenant, username, password, method: :old)
        expect(result).to eq(:old_result)
      end
    end
  end
end
