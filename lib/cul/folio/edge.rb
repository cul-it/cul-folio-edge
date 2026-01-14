require 'cul/folio/edge/version'
require 'rest-client'
require 'json'

module CUL
  module FOLIO
    module Edge
      class Error < StandardError; end
      class AuthenticationError < Error; end

        ##
        # Connects to a FOLIO API gateway and uses an authentication endpoint
        # to authenticate the user. 
        #
        # Params:
        # +okapi+:: URL of a FOLIO API gateway (e.g., "https://folio-snapshot-okapi.dev.folio.org")
        # +tenant+:: FOLIO tenant ID
        # +username+:: Username
        # +password+:: Password
        # +method+:: :new or :old, specifying which authentication scheme is used by the gateway
        #
        # Return:
        # A hash containing:
        # +:token+:: A FOLIO Access Token, or nil
        # +:token_exp+:: The expiration date of the token, or nil
        # +:code+:: An HTTP response code
        # +:error+:: An error message, or nil
        ##
        def self.authenticate(okapi, tenant, username, password, method: :new)
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

          if method == :new
            self.authenticate_new(okapi, headers, body)
          else
            self.authenticate_old(okapi, headers, body)
          end
        end

        ##
        # Connects to a FOLIO API gateway and uses the +/users+ endpoint
        # to retrieve a user's FOLIO record.
        #
        # Params:
        # +okapi+:: URL of a FOLIO API gateway (e.g., "https://folio-snapshot-okapi.dev.folio.org")
        # +tenant+:: A FOLIO tenant ID
        # +token+:: A FOLIO auth token string from a previous authentication call
        # +username+:: The 'username' property of a user record in FOLIO (For CUL, this is the user's NetId) 
        #
        # Return:
        # A hash containing:
        # +:user+:: A FOLIO user's record, or nil
        # +:code+:: An HTTP response code
        # +:error+:: An error message, or nil
        ##
        def self.patron_record(okapi, tenant, token, username)
          check_token(token)
          url = "#{okapi}/users?query=(username==#{username})"
          headers = {
            'X-Okapi-Tenant' => tenant,
            'x-okapi-token' => token,
            :accept => 'application/json',
          }
          return_value = {
            :user => nil,
            :error => nil,
          }

          begin
            response = RestClient.get(url, headers)
            # Convert from JSON to hash (JSON is in the form 
            # {'users': [array of users], 'totalRecords', 'resultInfo': {}})
            results = JSON.parse(response.body)
            users = results['users']
            if users.count == 1
              return_value[:user] = users[0]
              return_value[:code] = response.code
            else
              return_value[:code] = 500
              return_value[:error] = 'Could\'nt find user record'
            end
          rescue RestClient::ExceptionWithResponse => err
            return_value[:code] = err.response.code
            return_value[:error] = err.response.body
          end

          return return_value
        end

        ##
        # Connects to a FOLIO API gateway and uses the +/patron/account+ endpoint
        # from the +edge-patron+ module to retrieve a user's account information
        #
        # Params:
        # +okapi+:: URL of a FOLIO API gateway (e.g., "https://folio-snapshot-okapi.dev.folio.org")
        # +tenant+:: A FOLIO tenant ID
        # +token+:: A FOLIO auth token string from a previous authentication call
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
          check_token(token)
          folio_id = identifiers[:folio_id]
          if folio_id.nil?
            # TODO: Add error checking here -- :username could be blank, or the return from
            # patron_uuid could fail
            response = self.patron_record(okapi, tenant, token, identifiers[:username])
            if response[:code] < 300
              folio_id = response[:user]['id']
            else
              # We don't have an identifier for the user, so there's no point in continuing
              return {
                :account => nil,
                :code => 500,
                :error => 'Couldn\'t identify user'
              }
            end
          end


          url = "#{okapi}/patron/account/#{folio_id}?includeLoans=true&includeHolds=true&includeCharges=true"
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
        # Connects to a FOLIO API gateway and uses the +/patron/account+ endpoint
        # from the +edge-patron+ module to renew an item
        #
        # Params:
        # +okapi+:: URL of a FOLIO API gateway (e.g., "https://folio-snapshot-okapi.dev.folio.org")
        # +tenant+:: A FOLIO tenant ID
        # +token+:: A FOLIO auth token string from a previous authentication call
        # +userId+:: A FOLIO user username
        # +itemId+:: A FOLIO item UUID
        #
        # Return:
        # A hash containing:
        # +:due_date+:: The new item due date, or nil
        # +:code+:: An HTTP response code
        # +:error+:: An error message, or nil
        ##
        def self.renew_item(okapi, tenant, token, username, itemId)
          check_token(token)
          userId = self.patron_record(okapi, tenant, token, username)[:user]['id']
          # TODO: Add error checking here -- :username could be blank, or the return from
          # patron_uuid could fail

          url = "#{okapi}/patron/account/#{userId}/item/#{itemId}/renew"
          headers = {
            'X-Okapi-Tenant' => tenant,
            'x-okapi-token' => token,
            :accept => 'application/json',
          }
          return_value = {
            :due_date => nil,
            :error => nil,
          }

          begin
            response = RestClient.post(url,{}, headers)
            return_value[:code] = response.code
            return_value[:due_date] = JSON.parse(response.body)['dueDate']
          rescue RestClient::ExceptionWithResponse => err
            return_value[:code] = err.response.code
            return_value[:error] = JSON.parse(err.response.body)
          end

          return return_value
        end

        ##
        # Connects to a FOLIO API gateway and uses the +/circulation/rules/request-policy+ endpoint
        # and the +/request-policy-storage/request-policies+ endpoint
        # to determine which request methods can be used for the patron/item/location combination
        # specified.
        #
        # Params:
        # +okapi+:: URL of a FOLIO API gateway (e.g., "https://folio-snapshot-okapi.dev.folio.org")
        # +tenant+:: A FOLIO tenant ID
        # +token+:: A FOLIO auth token string from a previous authentication call
        # +patronGroupId+:: A FOLIO patron group UUID
        # +materialTypeId+:: A FOLIO material type UUID (NOTE that the FOLIO API calls this parameter
        # "item type")
        # +loanTypeId+:: A FOLIO loan type UUID
        # +locationId+:: A FOLIO location UUID
        #
        # Return:
        # A hash containing:
        # +:request_methods+:: An array of allowed delivery methods. Can include +:hold+, +:recall+, and +:l2l+ 
        # +:code+:: An HTTP response code
        # +:error+:: An error message, or nil
        ##
        def self.request_options(okapi, tenant, token, patronGroupId, materialTypeId, loanTypeId, locationId)
          check_token(token)

          # Step 1: Plug info about the item and patron in to the circ rules calculator to identify which
          # request policy should be applied
          url = "#{okapi}/circulation/rules/request-policy?item_type_id=#{materialTypeId}&loan_type_id=#{loanTypeId}&patron_type_id=#{patronGroupId}&location_id=#{locationId}"
          headers = {
            'X-Okapi-Tenant' => tenant,
            'x-okapi-token' => token,
            :accept => 'application/json',
          }
          return_value = {
            :request_methods => [],
            :error => nil,
          }

          begin
            response = RestClient.get(url, headers)
            return_value[:code] = response.code
          rescue RestClient::ExceptionWithResponse => err
            return_value[:code] = err.response.code
            return_value[:error] = err.response.body
            return return_value
          end

          # Step 2: assuming we got a valid match in Step 1, look up the specified request policy to
          # get the list of available delivery methods
          policyId = JSON.parse(response.body)['requestPolicyId']
          url = "#{okapi}/request-policy-storage/request-policies/#{policyId}"
          begin
            response = RestClient.get(url, headers)
            return_value[:code] = response.code
          rescue RestClient::ExceptionWithResponse => err
            return_value[:code] = err.response.code
            return_value[:error] = err.response.body
          end

          # Translate the specified request types into symbols
          type_map = {
            'Hold' => :hold,
            'Page' => :l2l,
            'Recall' => :recall
          }
          codes = JSON.parse(response.body)['requestTypes']
          return_value[:request_methods] = codes ? codes.map { |c| type_map[c] } : []

          return return_value
        end
        
        ##
        # Connects to a FOLIO API gateway and uses the +/inventory/instances+ endpoint
        # to retrieve an instance record for the specified UUID.
        #
        # Params:
        # +okapi+:: URL of a FOLIO API gateway (e.g., "https://folio-snapshot-okapi.dev.folio.org")
        # +tenant+:: A FOLIO tenant ID
        # +token+:: A FOLIO auth token string from a previous authentication call
        # +instanceId+:: A FOLIO instance record UUID
        #
        # Return:
        # A hash containing:
        # +:instance+:: An object representing the instance record
        # +:code+:: An HTTP response code
        # +:error+:: An error message, or nil
        ##
        def self.instance_record(okapi, tenant, token, instanceId)
          check_token(token)
          url = "#{okapi}/inventory/instances/#{instanceId}"
          headers = {
            'X-Okapi-Tenant' => tenant,
            'x-okapi-token' => token,
            :accept => 'application/json',
          }
          return_value = {
            :instance => nil,
            :error => nil,
          }

          begin
            response = RestClient.get(url, headers)
            return_value[:instance] = JSON.parse(response.body)
            return_value[:code] = response.code
          rescue RestClient::ExceptionWithResponse => err
            return_value[:code] = err.response.code
            return_value[:error] = err.response.body
          end

          return return_value
        end

        ##
        # Connects to a FOLIO API gateway and uses the +/circulation/requests+ endpoint
        # to create a new FOLIO request.
        #
        # Params:
        # +okapi+:: URL of a FOLIO API gateway (e.g., "https://folio-snapshot-okapi.dev.folio.org")
        # +tenant+:: A FOLIO tenant ID
        # +token+:: A FOLIO auth token string from a previous authentication call
        # +instanceId+:: UUID of the item's parent instance record
        # +holdingsId+:: UUID of the item's parent holdings record
        # +itemId+:: UUID of the item requested
        # +requesterId+:: UUID of the requester
        # +requestType+:: Hold, Recall, or Page
        # +requestDate+:: String date of the request (e.g., "2017-07-29T22:25:37Z")
        # +fulfillmentPreference+:: 'Hold Shelf' or 'Delivery'
        # +servicePointId+:: UUID of the pickup service point
        # +comments+:: Patron comments (optional)
        # +requestLevel+:: 'Item' (optional, added now for future-proofing; eventually there will be another choice for title-level requests)
        #
        # Return:
        # A hash containing:
        # +:code+:: An HTTP response code
        # +:error+:: An error message, or nil
        ##
        def self.request_item(okapi, tenant, token, instanceId, holdingsId, itemId, requesterId, requestType, requestDate, fulfillmentPreference, servicePointId, comments = '', requestLevel = 'Item')
          check_token(token)
          url = "#{okapi}/circulation/requests"
          headers = {
            'X-Okapi-Tenant' => tenant,
            'x-okapi-token' => token,
            :accept => 'application/json',
          }

          body = {
            'instanceId' => instanceId,
            'holdingsRecordId' => holdingsId,
            'itemId' => itemId,
            'requesterId' => requesterId,
            'requestType' => requestType,
            'requestDate' => requestDate,
            'requestLevel' => requestLevel,
            'fulfillmentPreference' => fulfillmentPreference,
            'pickupServicePointId' => servicePointId,
          }

          if comments != ''
            body['patronComments'] = comments
          end

          body = body.to_json

          return_value = {}
          begin
            response = RestClient.post(url, body, headers)
            return_value[:code] = response.code
            return_value[:error] = nil
          rescue RestClient::ExceptionWithResponse => err
            return_value[:code] = err.response.code
            return_value[:error] = err.response.body
          end

          return return_value
        end

        ##
        # Connects to a FOLIO API gateway and uses the +/circulation/requests+ endpoint
        # to cancel an existing FOLIO request.
        #
        # Params:
        # +okapi+:: URL of the FOLIO API gateway
        # +tenant+:: A FOLIO tenant ID required in the header by FOLIO
        # +token+:: A FOLIO auth token string from a previous call
        # +requestId+:: UUID of the request to be cancelled
        # +reasonId+:: UUID of a request cancellation reason 
        #
        # Return:
        # A hash containing:
        # +:code+:: An HTTP response code
        # +:error+:: An error message, or nil
        ##
        def self.cancel_request(okapi, tenant, token, requestId, reasonId)
          check_token(token)
          url = "#{okapi}/circulation/requests/#{requestId}"
          headers = {
            'X-Okapi-Tenant' => tenant,
            'x-okapi-token' => token,
            :accept => 'application/json',
          }

          # This is a bit unfortunate. In order to cancel, we have to make a PUT
          # request ... but for that, we need the current request object (so we
          # don't lose the established properties). Since we're only given the
          # request ID as a param, we'll have to do a lookup first in order to
          # retrieve the request, then update it -- a two-step process.
          #
          # Step 1: retrieval
          return_value = {}
          begin
            response = RestClient.get(url, headers)
            return_value[:code] = response.code
            return_value[:error] = nil
          rescue RestClient::ExceptionWithResponse => err
            return_value[:code] = err.response.code
            return_value[:error] = err.response.body
            return return_value
          end

          return return_value if return_value[:code] > 200

          # Step 2: cancellation
          request_data = JSON.parse(response.body)
          # Add cancellation-related fields to the request body
          request = {
            'id' => request_data['id'],
            'status' => 'Closed - Cancelled',
            'cancellationReasonId' => reasonId,
            'cancelledByUserId' => request_data['requesterId'],
            'cancellationAdditionalInformation' => 'Cancelled by user in My Account',
            'cancelledDate' => Time.now.utc.iso8601,
            'requestLevel' => request_data['requestLevel'] || 'Item',
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

          return_value = {}
          begin
            response = RestClient.put(url, request.to_json, headers)
            return_value[:code] = response.code
            return_value[:error] = nil
          rescue RestClient::ExceptionWithResponse => err
            return_value[:code] = err.response.code
            return_value[:error] = err.response.body
          end

          return return_value
        end

        ##
        # Connects to a FOLIO API gateway and uses the +/service-points+ endpoint
        # to look up a service point based on ID.
        #
        # Params:
        # +okapi+:: URL of a FOLIO API gateway (e.g., "https://folio-snapshot-okapi.dev.folio.org")
        # +tenant+:: A FOLIO tenant ID
        # +token+:: A FOLIO auth token string from a previous authentication call
        # +spId:: UUID of a service point
        #
        # Return:
        # A hash containing:
        # +:service_point+:: a hash containing the service point object
        # +:code+:: An HTTP response code
        # +:error+:: An error message, or nil
        ##
        def self.service_point(okapi, tenant, token, spId)
          check_token(token)
          url = "#{okapi}/service-points/#{spId}"
          headers = {
            'X-Okapi-Tenant' => tenant,
            'x-okapi-token' => token,
            :accept => 'application/json',
          }
          return_value = {
            :service_point => nil,
            :error => nil,
          }

          begin
            response = RestClient.get(url, headers)
            return_value[:service_point] = JSON.parse(response.body)
            return_value[:code] = response.code
          rescue RestClient::ExceptionWithResponse => err
            return_value[:code] = err.response.code
            return_value[:error] = err.response.body
          end

          return return_value
        end

        private

        # Private methods to handle the two different approaches to authentication
        # that FOLIO has used. The first method is the older one, which uses the
        # +/authn/login+ endpoint. The second method is the newer one, which uses
        # the +/authn/login-with-expiry+ endpoint. The newer method uses FOLIO's
        # Refresh Token Rotation approach to authentication.
 
        ##
        # This first version of the authentication method is intended for use with the 'classic'
        # FOLIO authentication method, which returns an access token that has an indefinite
        # TTL. This method is deprecated in favor of the newer method, which uses Refresh Token
        # Rotation, but is still included here for backwards compatibility with systems that
        # haven't upgraded FOLIO.
        ##
        def self.authenticate_old(okapi_url, headers, body)
          url = "#{okapi_url}/authn/login"
          self.authenticate_request(url, headers, body, :old)
        end        

        ##
        # This version of the authentication method is intended for use with
        # FOLIO's new Refresh Token Rotation approach to authentication, which is detailed
        # at https://folio-org.atlassian.net/wiki/spaces/FOLIJET/pages/1396980/Refresh+Token+Rotation+RTR.
        #
        # Note that the return value ignores the refresh token that FOLIO provides. Since this library
        # is intended for short-lived interactions with FOLIO, the refresh token is not needed. The access
        # token should have a sufficient TTL for the duration of the interaction.
        ##
        def self.authenticate_new(okapi_url, headers, body)
          url = "#{okapi_url}/authn/login-with-expiry"
          self.authenticate_request(url, headers, body, :new)
        end

        # Authenticates a request to the given FOLIO API gateway URL with the provided headers and body.
        #
        # @param url [String] the FOLIO API gateway URL to send the request to
        # @param headers [Hash] the headers to include in the request
        # @param body [String] the body of the request
        # @param method [Symbol] the method to use for authentication (:new or other)
        # @return [Hash] a hash containing the authentication token, error message (if any), and response code
        #   - :token [String, nil] the authentication token if successful, or nil if not
        #   - :error [String, nil] the error message if the request failed, or nil if successful
        #   - :code [Integer] the HTTP response code
        #   - :token_exp [String, nil] the token expiration time if the method is :new, or nil otherwise
        def self.authenticate_request(url, headers, body, method)
          return_value = {
            :token => nil,
            :error => nil,
          }

          begin
            response = RestClient.post(url, body, headers)
            if method == :new
              cookies = response.headers[:set_cookie]
              cookies.each do |cookie|
                if cookie.start_with?('folioAccessToken=')
                  return_value[:token] = cookie.match(/folioAccessToken=(.*?);/)[1]
                  return_value[:token_exp] = JSON.parse(response.body)['accessTokenExpiration']
                  break
                end
              end
            else
              return_value[:token] = response.headers[:x_okapi_token]
            end
            return_value[:code] = response.code
          rescue RestClient::ExceptionWithResponse => err
            return_value[:code] = err.response.code
            return_value[:error] = err.response.body
          rescue RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout, SocketError => err
            return_value[:code] = err.response.code if err.respond_to?(:response) && err.response
            return_value[:error] = "Network error: #{err.class} - #{err.message}"
          end
  
          return_value
        end

        # Raises AuthenticationError if token is missing or empty
        def self.check_token(token)
          if token.to_s.strip.empty?
            raise AuthenticationError, 'Authentication token is missing.'
          end
        end
        private_class_method :check_token
    end
  end
end
