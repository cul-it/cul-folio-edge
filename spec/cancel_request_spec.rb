require 'cul/folio/edge'
require 'rest-client'
require 'time'

RSpec.describe CUL::FOLIO::Edge do
  describe '.cancel_request' do
    let(:okapi) { 'https://folio.example.com' }
    let(:tenant) { 'test_tenant' }
    let(:token) { 'test_token' }
    let(:requestId) { 'request-123' }
    let(:reasonId) { 'reason-456' }
    let(:headers) do
      {
        'X-Okapi-Tenant' => tenant,
        'x-okapi-token' => token,
        :accept => 'application/json',
      }
    end
    let(:url) { "#{okapi}/circulation/requests/#{requestId}" }
    let(:request_data) do
      {
        'id' => requestId,
        'requesterId' => 'user-789',
        'requestLevel' => 'Item',
        'fulfillmentPreference' => 'Hold Shelf',
        'instanceId' => 'instance-111',
        'itemId' => 'item-222',
        'holdingsRecordId' => 'holdings-333',
        'requestDate' => '2026-01-06T12:00:00Z',
        'pickupServicePointId' => 'sp-444',
        'patronComments' => 'Cancel this',
        'requestType' => 'Hold'
      }
    end
    let(:get_response) { double('response', code: 200, body: request_data.to_json) }
    let(:put_body) do
      {
        'id' => requestId,
        'status' => 'Closed - Cancelled',
        'cancellationReasonId' => reasonId,
        'cancelledByUserId' => request_data['requesterId'],
        'cancellationAdditionalInformation' => 'Cancelled by user in My Account',
        'cancelledDate' => kind_of(String),
        'requestLevel' => request_data['requestLevel'],
        'fulfillmentPreference' => request_data['fulfillmentPreference'],
        'instanceId' => request_data['instanceId'],
        'itemId' => request_data['itemId'],
        'holdingsRecordId' => request_data['holdingsRecordId'],
        'requestDate' => request_data['requestDate'],
        'pickupServicePointId' => request_data['pickupServicePointId'],
        'patronComments' => request_data['patronComments'],
        'requesterId' => request_data['requesterId'],
        'requestType' => request_data['requestType']
      }
    end
    let(:put_response) { double('response', code: 204, body: '') }

    context 'when both GET and PUT succeed' do
      it 'returns code 204 and no error' do
        allow(RestClient).to receive(:get).with(url, headers).and_return(get_response)
        allow(RestClient).to receive(:put).with(url, satisfy { |body, _| JSON.parse(body).merge('cancelledDate' => kind_of(String)) }, headers).and_return(put_response)
        result = described_class.cancel_request(okapi, tenant, token, requestId, reasonId)
        expect(result[:code]).to eq(204)
        expect(result[:error]).to be_nil
      end
    end

    context 'when GET fails' do
      let(:error_response) { double('response', code: 404, body: 'Not found') }
      let(:exception) { RestClient::ExceptionWithResponse.new(error_response) }

      it 'returns the error code and message from GET' do
        allow(RestClient).to receive(:get).with(url, headers).and_raise(exception)
        result = described_class.cancel_request(okapi, tenant, token, requestId, reasonId)
        expect(result[:code]).to eq(404)
        expect(result[:error]).to eq('Not found')
      end
    end

    context 'when GET returns > 200' do
      let(:get_response) { double('response', code: 400, body: 'Bad request') }

      it 'returns the error code from GET' do
        allow(RestClient).to receive(:get).with(url, headers).and_return(get_response)
        result = described_class.cancel_request(okapi, tenant, token, requestId, reasonId)
        expect(result[:code]).to eq(400)
        expect(result[:error]).to be_nil
      end
    end

    context 'when PUT fails' do
      let(:error_response) { double('response', code: 500, body: 'Internal error') }
      let(:exception) { RestClient::ExceptionWithResponse.new(error_response) }

      it 'returns the error code and message from PUT' do
        allow(RestClient).to receive(:get).with(url, headers).and_return(get_response)
        allow(RestClient).to receive(:put).with(url, satisfy { |body, _| JSON.parse(body).merge('cancelledDate' => kind_of(String)) }, headers).and_raise(exception)
        result = described_class.cancel_request(okapi, tenant, token, requestId, reasonId)
        expect(result[:code]).to eq(500)
        expect(result[:error]).to eq('Internal error')
      end
    end
  end
end
