require 'cul/folio/edge'
require 'rest-client'
require 'support/shared_contexts'

RSpec.describe CUL::FOLIO::Edge do
  include_context 'FOLIO Edge API setup'
  describe '.request_item' do
    let(:instanceId) { 'instance-123' }
    let(:holdingsId) { 'holdings-456' }
    let(:itemId) { 'item-789' }
    let(:requesterId) { 'user-111' }
    let(:requestType) { 'Hold' }
    let(:requestDate) { '2026-01-06T12:00:00Z' }
    let(:fulfillmentPreference) { 'Hold Shelf' }
    let(:servicePointId) { 'sp-222' }
    let(:comments) { 'Please hold for pickup' }
    let(:requestLevel) { 'Item' }
    let(:url) { "#{okapi}/circulation/requests" }
    let(:body_hash) do
      {
        'instanceId' => instanceId,
        'holdingsRecordId' => holdingsId,
        'itemId' => itemId,
        'requesterId' => requesterId,
        'requestType' => requestType,
        'requestDate' => requestDate,
        'requestLevel' => requestLevel,
        'fulfillmentPreference' => fulfillmentPreference,
        'pickupServicePointId' => servicePointId,
        'patronComments' => comments
      }
    end
    let(:body_json) { body_hash.to_json }

    context 'when the request is successful' do
      let(:response_double) { double('response', code: 201, body: '{}') }

      it 'returns code 201 and no error' do
        allow(RestClient).to receive(:post).with(url, body_json, default_headers).and_return(response_double)
        result = described_class.request_item(okapi, tenant, token, instanceId, holdingsId, itemId, requesterId, requestType, requestDate, fulfillmentPreference, servicePointId, comments, requestLevel)
        expect(result[:code]).to eq(201)
        expect(result[:error]).to be_nil
      end
    end

    context 'when the request fails' do
      let(:error_response) { double('response', code: 422, body: 'Invalid request') }
      let(:exception) { RestClient::ExceptionWithResponse.new(error_response) }

      it 'returns the error code and message' do
        allow(RestClient).to receive(:post).with(url, body_json, default_headers).and_raise(exception)
        result = described_class.request_item(okapi, tenant, token, instanceId, holdingsId, itemId, requesterId, requestType, requestDate, fulfillmentPreference, servicePointId, comments, requestLevel)
        expect(result[:code]).to eq(422)
        expect(result[:error]).to eq('Invalid request')
      end
    end

    context 'when comments are blank' do
      let(:comments) { '' }
      let(:body_hash) do
        {
          'instanceId' => instanceId,
          'holdingsRecordId' => holdingsId,
          'itemId' => itemId,
          'requesterId' => requesterId,
          'requestType' => requestType,
          'requestDate' => requestDate,
          'requestLevel' => requestLevel,
          'fulfillmentPreference' => fulfillmentPreference,
          'pickupServicePointId' => servicePointId
        }
      end
      let(:body_json) { body_hash.to_json }
      let(:response_double) { double('response', code: 201, body: '{}') }

      it 'does not include patronComments in the body' do
        allow(RestClient).to receive(:post).with(url, body_json, default_headers).and_return(response_double)
        result = described_class.request_item(okapi, tenant, token, instanceId, holdingsId, itemId, requesterId, requestType, requestDate, fulfillmentPreference, servicePointId, comments, requestLevel)
        expect(result[:code]).to eq(201)
        expect(result[:error]).to be_nil
      end
    end
  end
end
