# Release Notes - cul-folio-edge

## [IN PROGRESS]
### Changed
- Update code comments to replace 'Okapi' with more generic references to API gateway (today Kong, tomorrow ...?)
- Non-authentication methods will raise an `AuthenticationError` if called with a nil token (DACCESS-807)

### Fixed
- Properly handle network-level errors in authentication (DACCESS-807)


## [3.3] - 2026-01-05
### Changed
- Upcoming Sunflower Folio change, we are moving from Okapi to Kong. Updated the `cancel` method to support Kong's smaller payload (DACCESS-673)

## [3.2] - 2025-01-09
### Changed
- Updated the `authenticate` method to support both new and old token systems in FOLIO (DACCESS-459)

## [3.1] - 2024-08-12
### Changed
- Updated the `authenticate` method to use the new token rotation/refresh system implemented in Quesnalia, Ransoms, and higher (DACCESS-261)

## 3.0
- Update the `request_item` method for FOLIO Poppy change to spelling of `fulfillmentPreference` (DACCESS-207)
- Add basic test setup using RSpec, VCR, and initial tests (cf. DACCESS-97)
- Update README

## 2.0d
- Modify the `request_item` method to add new required parameters for FOLIO Lotus (DISCOVERYACCESS-7496)

## 1.2.1
- Fix bug causing requests to be deleted rather than properly cancelled

## 1.2
- Add service_point function

## 1.1
- Return due date with a renewal response
- Return renewal error response as JSON

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