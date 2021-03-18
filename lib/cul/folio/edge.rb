require 'cul/folio/edge/version'
require 'rest-client'
require 'json'

module Cul
  module Folio
    module Edge
     class Error < StandardError; end
      # Your code goes here...

        ##
        # Connects to an Okapi instance and uses the +/authn/login+ endpoint
        # to authenticate the user.
        #
        # Params:
        # +okapi+:: URL of an okapi instance (e.g., "https://folio-snapshot-okapi.dev.folio.org")
        # +username+:: Username
        # +password+:: Password
        #
        # Return:
        # A hash containing:
        # +:token+:: An Okapi X-Okapi-Token string, or nil
        # +:code+:: An HTTP response code
        # +:error+:: An error message, or nil  
        def self.authenticate(okapi, username, password)
          url = "#{okapi}/authn/login"
          headers = {
            'X-Okapi-Tenant' => 'diku',
            :accept => 'application/json',
            'X-Forwarded-For' => 'Stripes',
            :content_type => 'application/json'
          }
          body = {
            'username' => username,
            'password' => password
          }.to_json

          return_value = {
            :token => nil,
            :error => nil,
          }

          begin
            response = RestClient.post(url, body, headers)
            return_value[:token] = response.headers[:x_okapi_token]
            return_value[:code] = response.code
          rescue RestClient::ExceptionWithResponse => err
            return_value[:code] = err.response.code
            return_value[:error] = err.response.body
          end

          return return_value
        end


    end
  end
end
