require 'cul/folio/edge'
require 'rest-client'
require 'support/shared_contexts'

RSpec.describe CUL::FOLIO::Edge do
  include_context 'FOLIO Edge API setup'
  describe '.patron_account' do
    let(:folio_id) { 'abc123' }
    let(:username) { 'testuser' }
    let(:identifiers) { { folio_id: folio_id, username: username } }
    let(:url) { "#{okapi}/patron/account/#{folio_id}?includeLoans=true&includeHolds=true&includeCharges=true" }

    context 'when folio_id is provided' do
      let(:account_data) { { 'loans' => [], 'holds' => [], 'charges' => [] } }
      let(:response_double) { double('response', body: account_data.to_json, code: 200) }

      it 'returns the account data and code 200' do
        allow(RestClient).to receive(:get).with(url, default_headers).and_return(response_double)
        result = described_class.patron_account(okapi, tenant, token, identifiers)
        expect(result[:account]).to eq(account_data)
        expect(result[:code]).to eq(200)
        expect(result[:error]).to be_nil
      end
    end

    context 'when folio_id is nil and user is found' do
      let(:identifiers) { { folio_id: nil, username: username } }
      let(:user) { { 'id' => folio_id, 'username' => username } }
      let(:patron_record_response) { { user: user, code: 200, error: nil } }
      let(:account_data) { { 'loans' => [], 'holds' => [], 'charges' => [] } }
      let(:response_double) { double('response', body: account_data.to_json, code: 200) }

      it 'looks up user and returns account data' do
        allow(described_class).to receive(:patron_record).with(okapi, tenant, token, username).and_return(patron_record_response)
        allow(RestClient).to receive(:get).with(url, default_headers).and_return(response_double)
        result = described_class.patron_account(okapi, tenant, token, identifiers)
        expect(result[:account]).to eq(account_data)
        expect(result[:code]).to eq(200)
        expect(result[:error]).to be_nil
      end
    end

    context 'when folio_id is nil and user is not found' do
      let(:identifiers) { { folio_id: nil, username: username } }
      let(:patron_record_response) { { user: nil, code: 500, error: 'Couldn\'t find user record' } }

      it 'returns error and code 500' do
        allow(described_class).to receive(:patron_record).with(okapi, tenant, token, username).and_return(patron_record_response)
        result = described_class.patron_account(okapi, tenant, token, identifiers)
        expect(result[:account]).to be_nil
        expect(result[:code]).to eq(500)
        expect(result[:error]).to eq("Couldn't identify user")
      end
    end

    context 'when RestClient raises an exception' do
      let(:error_response) { double('response', code: 404, body: 'Not found') }
      let(:exception) { RestClient::ExceptionWithResponse.new(error_response) }

      it 'returns the error code and message' do
        allow(RestClient).to receive(:get).with(url, default_headers).and_raise(exception)
        result = described_class.patron_account(okapi, tenant, token, identifiers)
        expect(result[:account]).to be_nil
        expect(result[:code]).to eq(404)
        expect(result[:error]).to eq('Not found')
      end
    end
  end
end
