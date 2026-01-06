require 'cul/folio/edge'
require 'rest-client'

RSpec.describe CUL::FOLIO::Edge do
  describe '.patron_record' do
    let(:okapi) { 'https://folio.example.com' }
    let(:tenant) { 'test_tenant' }
    let(:token) { 'test_token' }
    let(:username) { 'testuser' }
    let(:headers) do
      {
        'X-Okapi-Tenant' => tenant,
        'x-okapi-token' => token,
        :accept => 'application/json',
      }
    end
    let(:url) { "#{okapi}/users?query=(username==#{username})" }

    context 'when a single user is found' do
      let(:user) { { 'id' => '123', 'username' => username } }
      let(:response_double) { double('response', body: { 'users' => [user], 'totalRecords' => 1 }.to_json, code: 200) }

      it 'returns the user and code 200' do
        allow(RestClient).to receive(:get).with(url, headers).and_return(response_double)
        result = described_class.patron_record(okapi, tenant, token, username)
        expect(result[:user]).to eq(user)
        expect(result[:code]).to eq(200)
        expect(result[:error]).to be_nil
      end
    end

    context 'when no user is found' do
      let(:response_double) { double('response', body: { 'users' => [] }.to_json, code: 200) }

      it 'returns error and code 500' do
        allow(RestClient).to receive(:get).with(url, headers).and_return(response_double)
        result = described_class.patron_record(okapi, tenant, token, username)
        expect(result[:user]).to be_nil
        expect(result[:code]).to eq(500)
        expect(result[:error]).to match(/Could\'nt find user record/) # error message
      end
    end

    context 'when multiple users are found' do
      let(:users) { [{ 'id' => '1' }, { 'id' => '2' }] }
      let(:response_double) { double('response', body: { 'users' => users }.to_json, code: 200) }

      it 'returns error and code 500' do
        allow(RestClient).to receive(:get).with(url, headers).and_return(response_double)
        result = described_class.patron_record(okapi, tenant, token, username)
        expect(result[:user]).to be_nil
        expect(result[:code]).to eq(500)
        expect(result[:error]).to match(/Could\'nt find user record/) # error message
      end
    end

    context 'when RestClient raises an exception' do
      let(:error_response) { double('response', code: 404, body: 'Not found') }
      let(:exception) { RestClient::ExceptionWithResponse.new(error_response) }

      it 'returns the error code and message' do
        allow(RestClient).to receive(:get).with(url, headers).and_raise(exception)
        result = described_class.patron_record(okapi, tenant, token, username)
        expect(result[:user]).to be_nil
        expect(result[:code]).to eq(404)
        expect(result[:error]).to eq('Not found')
      end
    end
  end
end
