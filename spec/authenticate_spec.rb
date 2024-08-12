require 'cul/folio/edge'

describe CUL::FOLIO::Edge do
  describe 'authenticate' do
    let(:okapi) { ENV['OKAPI_URL'] }
    let(:tenant) { ENV['OKAPI_TENANT'] }

    it 'returns a token and no error for a valid request' do
      VCR.use_cassette('authentication_successful') do
        response = CUL::FOLIO::Edge.authenticate(okapi, tenant, ENV['OKAPI_USER'], ENV['OKAPI_PW'])
        expect(response[:token]).to_not be_nil
        expect { DateTime.parse(response[:token_exp]) }.not_to raise_error(TypeError)
        expect(response[:code]).to be(201)
        expect(response[:error]).to be_nil
      end
    end

    it 'returns an error and no token for an invalid request' do
      VCR.use_cassette('authentication_unsuccessful') do
        response = CUL::FOLIO::Edge.authenticate(okapi, tenant, 'George', 'letmein')
        expect(response[:token]).to be_nil
        expect { DateTime.parse(response[:token_exp]) }.to raise_error(TypeError)
        expect(response[:code]).to be(422)
        expect(response[:error]).to_not be_nil
      end
    end
  end
end
