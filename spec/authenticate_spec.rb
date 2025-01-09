require 'cul/folio/edge'

describe CUL::FOLIO::Edge do
  describe 'authenticate' do
    describe 'new authentication method (token rotation)' do
      let(:okapi) { ENV['OKAPI_URL'] }
      let(:tenant) { ENV['OKAPI_TENANT'] }

      it 'returns a token and no error for a valid request' do
        VCR.use_cassette('new_authentication_successful') do
          response = CUL::FOLIO::Edge.authenticate(okapi, tenant, ENV['OKAPI_USER'], ENV['OKAPI_PW'])
          expect(response[:token]).to_not be_nil
          expect { DateTime.parse(response[:token_exp]) }.not_to raise_error(TypeError)
          expect(response[:code]).to be(201)
          expect(response[:error]).to be_nil
        end
      end

      it 'returns an error and no token for an invalid request' do
        VCR.use_cassette('new_authentication_unsuccessful') do
          response = CUL::FOLIO::Edge.authenticate(okapi, tenant, 'George', 'letmein')
          expect(response[:token]).to be_nil
          expect { DateTime.parse(response[:token_exp]) }.to raise_error(TypeError)
          expect(response[:code]).to be(422)
          expect(response[:error]).to_not be_nil
        end
      end
    end

    describe 'old authentication method (non-expiring token)' do
      let(:okapi) { ENV['OLD_OKAPI_URL'] }
      let(:tenant) { ENV['OLD_OKAPI_TENANT'] }

      it 'returns a token and no error for a valid request' do
        VCR.use_cassette('old_authentication_successful') do
          response = CUL::FOLIO::Edge.authenticate(okapi, tenant, ENV['OLD_OKAPI_USER'], ENV['OLD_OKAPI_PW'], method: :old)
          expect(response[:token]).to_not be_nil
          expect(response[:code]).to be(201)
          expect(response[:error]).to be_nil
        end
      end

      it 'returns an error and no token for an invalid request' do
        VCR.use_cassette('old_authentication_unsuccessful') do
          response = CUL::FOLIO::Edge.authenticate(okapi, tenant, 'George', 'letmein', method: :old)
          expect(response[:token]).to be_nil
          expect(response[:code]).to be(422)
          expect(response[:error]).to_not be_nil
        end
      end
    end
  end
end
