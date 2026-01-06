require 'cul/folio/edge'
require 'rest-client'
require 'support/shared_contexts'

RSpec.describe CUL::FOLIO::Edge do
  include_context 'FOLIO Edge API setup'
  describe '.instance_record' do
    let(:instanceId) { 'instance-123' }
    let(:url) { "#{okapi}/inventory/instances/#{instanceId}" }

    context 'when the API call succeeds' do
      let(:instance_data) { { 'id' => instanceId, 'title' => 'Test Title' } }
      let(:response_double) { double('response', body: instance_data.to_json, code: 200) }

      it 'returns the instance data and code 200' do
        allow(RestClient).to receive(:get).with(url, default_headers).and_return(response_double)
        result = described_class.instance_record(okapi, tenant, token, instanceId)
        expect(result[:instance]).to eq(instance_data)
        expect(result[:code]).to eq(200)
        expect(result[:error]).to be_nil
      end
    end

    context 'when the API call fails' do
      let(:error_response) { double('response', code: 404, body: 'Not found') }
      let(:exception) { RestClient::ExceptionWithResponse.new(error_response) }

      it 'returns the error code and message' do
        allow(RestClient).to receive(:get).with(url, default_headers).and_raise(exception)
        result = described_class.instance_record(okapi, tenant, token, instanceId)
        expect(result[:instance]).to be_nil
        expect(result[:code]).to eq(404)
        expect(result[:error]).to eq('Not found')
      end
    end
  end
end
