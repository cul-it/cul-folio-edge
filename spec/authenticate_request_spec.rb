require 'cul/folio/edge'
require 'rest-client'

RSpec.describe CUL::FOLIO::Edge do
  describe '.authenticate_request' do
    let(:url) { 'https://folio.example.com/authn/login' }
    let(:headers) do
      {
        'X-Okapi-Tenant' => 'test_tenant',
        :accept => 'application/json',
        'X-Forwarded-For' => 'Stripes',
        :content_type => 'application/json'
      }
    end
    let(:body) { { 'username' => 'testuser', 'password' => 'secret' }.to_json }

    context 'when method is :new and authentication succeeds' do
      let(:cookie) { 'folioAccessToken=abc123; Path=/; HttpOnly' }
      let(:response_double) do
        double('response',
          headers: { set_cookie: [cookie] },
          body: { 'accessTokenExpiration' => '2026-02-01T00:00:00Z' }.to_json,
          code: 201
        )
      end

      it 'returns token, token_exp, and code' do
        allow(RestClient).to receive(:post).with(url, body, headers).and_return(response_double)
        result = described_class.authenticate_request(url, headers, body, :new)
        expect(result[:token]).to eq('abc123')
        expect(result[:token_exp]).to eq('2026-02-01T00:00:00Z')
        expect(result[:code]).to eq(201)
        expect(result[:error]).to be_nil
      end
    end

    context 'when method is :old and authentication succeeds' do
      let(:response_double) do
        double('response',
          headers: { x_okapi_token: 'oldtoken' },
          code: 201
        )
      end

      it 'returns token and code' do
        allow(RestClient).to receive(:post).with(url, body, headers).and_return(response_double)
        result = described_class.authenticate_request(url, headers, body, :old)
        expect(result[:token]).to eq('oldtoken')
        expect(result[:code]).to eq(201)
        expect(result[:error]).to be_nil
      end
    end

    context 'when authentication fails' do
      let(:error_response) { double('response', code: 401, body: 'Unauthorized') }
      let(:exception) { RestClient::ExceptionWithResponse.new(error_response) }

      it 'returns the error code and message' do
        allow(RestClient).to receive(:post).with(url, body, headers).and_raise(exception)
        result = described_class.authenticate_request(url, headers, body, :new)
        expect(result[:token]).to be_nil
        expect(result[:code]).to eq(401)
        expect(result[:error]).to eq('Unauthorized')
      end
    end
  end
end
