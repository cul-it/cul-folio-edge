# Release Notes - cul-folio-edge

## 1.1
- Return due date with a renewal response

## 1.0
(Initial release)
Provides the following functions:
1. authenticate (provide a username and password to a FOLIO instance, get a token back)
2. patron_record (retrieve a FOLIO user's record)
3. patron_account (retrieve a user account details - checkouts, requests, fines and fees)
4. renew_item (renew a checked-out item)
5. request_options (use circulation rules and request policy to determine which request types are available)
6. instance_record (retrieve a FOLIO instance record)
7. request_item (place a new request for an item)
8. cancel_request (cancel an existing request for an item)