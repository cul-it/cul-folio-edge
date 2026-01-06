require 'cul/folio/edge'
require 'rest-client'
require 'support/shared_contexts'

RSpec.describe CUL::FOLIO::Edge do
  include_context 'FOLIO Edge API setup'
  describe '.renew_item' do
    let(:username) { 'testuser' }
    let(:itemId) { 'item123' }
    let(:userId) { 'user456' }
    let(:url) { "#{okapi}/patron/account/#{userId}/item/#{itemId}/renew" }

    context 'when renewal is successful' do
      let(:patron_record_response) { { user: { 'id' => userId }, code: 200, error: nil } }
      let(:response_double) { double('response', body: { 'dueDate' => '2026-01-31T23:59:59Z' }.to_json, code: 200) }

      it 'returns the new due date and code 200' do
        allow(described_class).to receive(:patron_record).with(okapi, tenant, token, username).and_return(patron_record_response)
        allow(RestClient).to receive(:post).with(url, {}, default_headers).and_return(response_double)
        result = described_class.renew_item(okapi, tenant, token, username, itemId)
        expect(result[:due_date]).to eq('2026-01-31T23:59:59Z')
        expect(result[:code]).to eq(200)
        expect(result[:error]).to be_nil
      end
    end

    context 'when renewal fails with error response' do
      let(:patron_record_response) { { user: { 'id' => userId }, code: 200, error: nil } }
      let(:error_body) { { 'error' => 'Renewal not allowed' }.to_json }
      let(:error_response) { double('response', code: 422, body: error_body) }
      let(:exception) { RestClient::ExceptionWithResponse.new(error_response) }

      it 'returns the error code and message' do
        allow(described_class).to receive(:patron_record).with(okapi, tenant, token, username).and_return(patron_record_response)
        allow(RestClient).to receive(:post).with(url, {}, default_headers).and_raise(exception)
        result = described_class.renew_item(okapi, tenant, token, username, itemId)
        expect(result[:due_date]).to be_nil
        expect(result[:code]).to eq(422)
        expect(result[:error]).to eq(JSON.parse(error_body))
      end
    end

    context 'when user is not found' do
      let(:patron_record_response) { { user: nil, code: 500, error: "Couldn't find user record" } }

      it 'raises NoMethodError when accessing id' do
        allow(described_class).to receive(:patron_record).with(okapi, tenant, token, username).and_return(patron_record_response)
        expect {
          described_class.renew_item(okapi, tenant, token, username, itemId)
        }.to raise_error(NoMethodError)
      end
    end
  end
end
