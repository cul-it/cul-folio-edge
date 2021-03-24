require 'cul/folio/edge/version'
require 'rest-client'
require 'json'

module CUL
  module FOLIO
    module Edge
     class Error < StandardError; end

        ##
        # Connects to an Okapi instance and uses the +/authn/login+ endpoint
        # to authenticate the user.
        #
        # Params:
        # +okapi+:: URL of an okapi instance (e.g., "https://folio-snapshot-okapi.dev.folio.org")
        # +tenant+:: FOLIO/OKAPI tenant ID
        # +username+:: Username
        # +password+:: Password
        #
        # Return:
        # A hash containing:
        # +:token+:: An Okapi X-Okapi-Token string, or nil
        # +:code+:: An HTTP response code
        # +:error+:: An error message, or nil
        ##
        def self.authenticate(okapi, tenant, username, password)
          url = "#{okapi}/authn/login"
          headers = {
            'X-Okapi-Tenant' => tenant,
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

        ##
        # Connects to an Okapi instance and uses the +/users+ endpoint
        # to get a user's UUID from his/her username.
        #
        # Params:
        # +okapi+:: URL of an okapi instance (e.g., "https://folio-snapshot-okapi.dev.folio.org")
        # +tenant+:: An Okapi tenant ID
        # +token+:: An Okapi token string from a previous authentication call
        # +username+:: The 'username' property of a user record in FOLIO (For CUL, this is the user's NetId) 
        #
        # Return:
        # A hash containing:
        # +:folio_id+:: A FOLIO user's UUID string, or nil
        # +:code+:: An HTTP response code
        # +:error+:: An error message, or nil
        ##
        def self.patron_uuid(okapi, tenant, token, username)
          url = "#{okapi}/users?query=(username==#{username})"
          headers = {
            'X-Okapi-Tenant' => tenant,
            'x-okapi-token' => token,
            :accept => 'application/json',
          }
          return_value = {
            :folio_id => nil,
            :error => nil,
          }

          begin
            response = RestClient.get(url, headers)
            # Convert from JSON to hash (JSON is in the form 
            # {'users': [array of users], 'totalRecords', 'resultInfo': {}})
            results = JSON.parse(response.body)
            users = results['users']
            if users.count == 1
              return_value[:folio_id] = users[0]['id']
              return_value[:code] = response.code
            else
              # TODO: This condition should never occur but should be guarded against anyway
            end
          rescue RestClient::ExceptionWithResponse => err
            return_value[:code] = err.response.code
            return_value[:error] = err.response.body
          end

          return return_value
        end

        ##
        # Connects to an Okapi instance and uses the +/patron/account+ endpoint
        # from the +edge-patron+ module to retrieve a user's account information
        #
        # Params:
        # +okapi+:: URL of an okapi instance (e.g., "https://folio-snapshot-okapi.dev.folio.org")
        # +tenant+:: An Okapi tenant ID
        # +token+:: An Okapi token string from a previous authentication call
        # +identifiers+:: A hash containing either a +:folio_id+ string (a FOLIO user's UUID)
        # or a +:username+ string (a FOLIO user's username)
        #
        # Return:
        # A hash containing:
        # +:account+:: A user's account information hash, or nil
        # +:code+:: An HTTP response code
        # +:error+:: An error message, or nil
        ##
        def self.patron_account(okapi, tenant, token, identifiers)
          folio_id = identifiers[:folio_id]
          if folio_id.nil?
            # TODO: Add error checking here -- :username could be blank, or the return from
            # patron_uuid could fail
            folio_id = self.patron_uuid(okapi, tenant, token, identifiers[:username])[:folio_id]
          end

          url = "#{okapi}/patron/account/#{folio_id}?includeLoans=true&includeHolds=true"
          headers = {
            'X-Okapi-Tenant' => tenant,
            'x-okapi-token' => token,
            :accept => 'application/json',
          }
          return_value = {
            :account => nil,
            :error => nil,
          }

          begin
            response = RestClient.get(url, headers)
            return_value[:account] = JSON.parse(response.body)
            return_value[:code] = response.code
          rescue RestClient::ExceptionWithResponse => err
            return_value[:code] = err.response.code
            return_value[:error] = err.response.body
          end

          return return_value
        end

        ##
        # Connects to an Okapi instance and uses the +/patron/account+ endpoint
        # from the +edge-patron+ module to renew an item
        #
        # Params:
        # +okapi+:: URL of an okapi instance (e.g., "https://folio-snapshot-okapi.dev.folio.org")
        # +tenant+:: An Okapi tenant ID
        # +token+:: An Okapi token string from a previous authentication call
        # +userId+:: A FOLIO user username
        # +itemId+:: A FOLIO item UUID
        #
        # Return:
        # A hash containing:
        # +:code+:: An HTTP response code
        # +:error+:: An error message, or nil
        ##
        def self.renew_item(okapi, tenant, token, username, itemId)
          userId = self.patron_uuid(okapi, tenant, token, identifiers[:username])[:folio_id]
          # TODO: Add error checking here -- :username could be blank, or the return from
          # patron_uuid could fail
          url = "#{okapi}/patron/account/#{userId}/item/#{itemId}/renew"
          headers = {
            'X-Okapi-Tenant' => tenant,
            'x-okapi-token' => token,
            :accept => 'application/json',
          }
          return_value = {
            :error => nil,
          }

          begin
            response = RestClient.post(url, headers)
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
