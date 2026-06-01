# junction-ruby

A small Ruby client for the [Junction](https://docs.junction.com) (formerly Vital) API.

## Installation

```ruby
# Gemfile — note the require override, since the gem name is hyphenated
gem 'junction-ruby', require: 'junction'
```

## Configuration

Configure once at boot. In Rails, `config/initializers/junction.rb`:

```ruby
Junction.configure do |c|
  c.api_key  = Rails.application.credentials.dig(:junction, :api_key) || ENV.fetch('JUNCTION_API_KEY')
  c.base_uri = Rails.env.production? ? 'https://api.us.junction.com'
                                     : 'https://api.sandbox.us.junction.com'
end
```

| Setting    | Default                                  | Notes                                            |
|------------|------------------------------------------|--------------------------------------------------|
| `api_key`  | `nil`                                    | Sent as the `x-vital-api-key` header.            |
| `base_uri` | `https://api.sandbox.us.junction.com`    | Region/env host (`api.us` / `api.eu`, sandbox or prod). |

## Usage

### Create, find, and resolve a user

`create`, `find`, and `find_by_client_user_id` all return the same user shape:

```ruby
junction_user = Junction::Users.create('development_14623')  # POST /v2/user
Junction::Users.find(junction_user['user_id'])               # GET  /v2/user/{user_id}
Junction::Users.find_by_client_user_id('development_14623')  # GET  /v2/user/resolve/{client_user_id}
# =>
# {"user_id"=>"649b5a17-9f9a-40ee-b729-6c1b14a2602f",
#  "team_id"=>"8ad7e3ec-df8a-4681-85e0-d7d71d80c169",
#  "client_user_id"=>"development_14623",
#  "created_on"=>"2026-06-01T19:17:28+00:00",
#  "connected_sources"=>[],
#  "fallback_time_zone"=>nil,
#  "fallback_birth_date"=>nil,
#  "ingestion_start"=>nil,
#  "ingestion_end"=>nil}
```

### Update user demographics

```ruby
Junction::Users.update_user_demographics(   # PATCH /v2/user/{user_id}/info
  junction_user['user_id'],
  first_name: 'John',
  last_name: 'Doe',
  email: 'john@email.com',
  phone_number: '+1123123123',
  gender: 'Male',
  dob: '1999-01-01',
  address: {
    first_line: 'Some Street',
    second_line: nil,
    state: 'AZ',
    city: 'Phoenix',
    country: 'US',
    zip: '85004'
  }
)
# =>
# {"first_name"=>"John",
#  "last_name"=>"Doe",
#  "email"=>"john@email.com",
#  "phone_number"=>"+1123123123",
#  "gender"=>"male",
#  "dob"=>"1999-01-01",
#  "address"=>
#   {"first_line"=>"Some Street",
#    "second_line"=>"",
#    "country"=>"US",
#    "zip"=>"85004",
#    "city"=>"Phoenix",
#    "state"=>"AZ",
#    "access_notes"=>nil},
#  "medical_proxy"=>nil,
#  "race"=>nil,
#  "ethnicity"=>nil,
#  "sexual_orientation"=>nil,
#  "gender_identity"=>nil}
```

Non-2xx responses raise `Junction::Client::RequestError`, which carries the
original `response` (`error.response.code`, `error.response.body`).

## Development

```bash
bundle install
bundle exec rspec
```
