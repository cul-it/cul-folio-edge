require 'cul/folio/edge'
require 'rest-client'
require 'support/shared_contexts'

RSpec.describe CUL::FOLIO::Edge do
  include_context 'FOLIO Edge API setup'
  describe '.request_options' do
    let(:patronGroupId) { 'patron-group' }
    let(:materialTypeId) { 'material-type' }
    let(:loanTypeId) { 'loan-type' }
    let(:locationId) { 'location-id' }
    let(:step1_url) { "#{okapi}/circulation/rules/request-policy?item_type_id=#{materialTypeId}&loan_type_id=#{loanTypeId}&patron_type_id=#{patronGroupId}&location_id=#{locationId}" }
    let(:policyId) { 'policy-123' }
    let(:step2_url) { "#{okapi}/request-policy-storage/request-policies/#{policyId}" }

    context 'when both API calls succeed' do
      let(:step1_response) { double('response', body: { 'requestPolicyId' => policyId }.to_json, code: 200) }
      let(:step2_response) { double('response', body: { 'requestTypes' => ['Hold', 'Recall', 'Page'] }.to_json, code: 200) }

      it 'returns allowed request methods and code 200' do
        allow(RestClient).to receive(:get).with(step1_url, default_headers).and_return(step1_response)
        allow(RestClient).to receive(:get).with(step2_url, default_headers).and_return(step2_response)
        result = described_class.request_options(okapi, tenant, token, patronGroupId, materialTypeId, loanTypeId, locationId)
        expect(result[:request_methods]).to contain_exactly(:hold, :recall, :l2l)
        expect(result[:code]).to eq(200)
        expect(result[:error]).to be_nil
      end
    end

    context 'when first API call fails' do
      let(:error_response) { double('response', code: 404, body: 'Not found') }
      let(:exception) { RestClient::ExceptionWithResponse.new(error_response) }

      it 'returns error and code from first call' do
        allow(RestClient).to receive(:get).with(step1_url, default_headers).and_raise(exception)
        result = described_class.request_options(okapi, tenant, token, patronGroupId, materialTypeId, loanTypeId, locationId)
        expect(result[:request_methods]).to eq([])
        expect(result[:code]).to eq(404)
        expect(result[:error]).to eq('Not found')
      end
    end

    context 'when second API call fails' do
      let(:step1_response) { double('response', body: { 'requestPolicyId' => policyId }.to_json, code: 200) }
      let(:error_response) { double('response', code: 500, body: 'Internal error') }
      let(:exception) { RestClient::ExceptionWithResponse.new(error_response) }

      it 'returns error and code from second call' do
        allow(RestClient).to receive(:get).with(step1_url, default_headers).and_return(step1_response)
        allow(RestClient).to receive(:get).with(step2_url, default_headers).and_raise(exception)
        result = described_class.request_options(okapi, tenant, token, patronGroupId, materialTypeId, loanTypeId, locationId)
        expect(result[:request_methods]).to eq([])
        expect(result[:code]).to eq(500)
        expect(result[:error]).to eq('Internal error')
      end
    end

    context 'when requestTypes is nil or empty' do
      let(:step1_response) { double('response', body: { 'requestPolicyId' => policyId }.to_json, code: 200) }
      let(:step2_response) { double('response', body: { 'requestTypes' => nil }.to_json, code: 200) }

      it 'returns empty request_methods array' do
        allow(RestClient).to receive(:get).with(step1_url, default_headers).and_return(step1_response)
        allow(RestClient).to receive(:get).with(step2_url, default_headers).and_return(step2_response)
        result = described_class.request_options(okapi, tenant, token, patronGroupId, materialTypeId, loanTypeId, locationId)
        expect(result[:request_methods]).to eq([])
        expect(result[:code]).to eq(200)
        expect(result[:error]).to be_nil
      end
    end
  end
end
