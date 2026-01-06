require 'cul/folio/edge'
require 'rest-client'
require 'support/shared_contexts'

RSpec.describe CUL::FOLIO::Edge do
  include_context 'FOLIO Edge API setup'
  describe '.service_point' do
    let(:spId) { 'sp-123' }
    let(:url) { "#{okapi}/service-points/#{spId}" }

    context 'when the API call succeeds' do
      let(:service_point_data) { { 'id' => spId, 'name' => 'Main Desk' } }
      let(:response_double) { double('response', body: service_point_data.to_json, code: 200) }

      it 'returns the service point data and code 200' do
        allow(RestClient).to receive(:get).with(url, default_headers).and_return(response_double)
        result = described_class.service_point(okapi, tenant, token, spId)
        expect(result[:service_point]).to eq(service_point_data)
        expect(result[:code]).to eq(200)
        expect(result[:error]).to be_nil
      end
    end

    context 'when the API call fails' do
      let(:error_response) { double('response', code: 404, body: 'Not found') }
      let(:exception) { RestClient::ExceptionWithResponse.new(error_response) }

      it 'returns the error code and message' do
        allow(RestClient).to receive(:get).with(url, default_headers).and_raise(exception)
        result = described_class.service_point(okapi, tenant, token, spId)
        expect(result[:service_point]).to be_nil
        expect(result[:code]).to eq(404)
        expect(result[:error]).to eq('Not found')
      end
    end
  end
end
