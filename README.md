# CUL::FOLIO::Edge

CUL::FOLIO::Edge is a Ruby wrapper for several [FOLIO](https://folio.org) APIs, originally developed for use with [Cornell University Library](https://library.cornell.edu)'s [Blacklight](https://projectblacklight.org) catalog.

The wrapped methods include:

| method | FOLIO API endpoint |
| ------ | ----- |
| authenticate | /authn/login |
| patron_record | /users |
| patron_account | /patron/account |
| renew_item | /patron/account |
| request_options | /circulation/rules/request-policy |
| | /request-policy-storage/request-policies |
| instance_record | /inventory/instances |
| request_item | /circulation/requests |
| cancel_request | /circulation/requests |
| service_point | /service-points |

Most of the methods are centered around the needs of discovery systems to retrieve patron account details and to request library materials.

Version 3.0 and higher of CUL::FOLIO::Edge requires FOLIO's Poppy release or above -- more specificially, `mod-circulation` v. 24.0 or higher.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cul-folio-edge'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install cul-folio-edge

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cul-folio-edge.

