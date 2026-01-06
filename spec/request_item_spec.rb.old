require 'spec_helper'
require 'cul/folio/edge'

describe CUL::FOLIO::Edge do
  describe ".request_item" do
    let(:okapi) { ENV['OKAPI_URL'] }
    let(:tenant) { ENV['OKAPI_TENANT'] }
    let(:token) { ENV['OKAPI_TOKEN'] }

    # The item metadata is for this record: https://catalog.library.cornell.edu/catalog/10483958
    let(:instanceId) { '33e31b39-c9f1-469a-84bf-ff144e9f594f' }
    let(:holdingsId) { '097481bf-dcd5-4745-a66e-f63410285a12' }
    let(:itemId) { '397905ac-819f-4bd6-8b2e-32925be9d5b8' }
    let(:requesterId) { ENV['USER_UUID'] }
    let(:requestType) { 'Hold' }
    let(:requestDate) { '2024-02-29T22:25:37Z' }
    let(:fulfilmentPreference) { 'Hold Shelf' }
    let(:servicePointId) { '760beccd-362d-45b6-bfae-639565a877f2' } # Olin Library
    let(:comments) { '' }
    let(:requestLevel) { 'Item' }


    describe '.request_item' do
      it 'returns a 201 and no errors for a successful request' do
        VCR.use_cassette('request_item_successful') do
          response = CUL::FOLIO::Edge.request_item(
            okapi,
            tenant,
            token,
            instanceId,
            holdingsId,
            itemId,
            requesterId,
            requestType,
            requestDate,
            fulfilmentPreference,
            servicePointId,
            comments,
            requestLevel
          )
          expect(response[:code]).to eq(201)
          expect(response[:error]).to be_nil
        end
      end

      # For VCR recording purposes, we don't need to change any values for the second request. Since
      # a request for the same item by the same borrower will fail, we can use the same values here.
      it 'returns a higher HTTP response and an error for an unsuccessful request' do
        VCR.use_cassette('request_item_error') do
          response = CUL::FOLIO::Edge.request_item(okapi, tenant, token, instanceId, holdingsId, itemId, requesterId, requestType, requestDate, fulfilmentPreference, servicePointId, comments, requestLevel)
          expect(response[:code]).to be > 300
          expect(response[:error]).not_to be_nil
        end
      end
    end
  end
end