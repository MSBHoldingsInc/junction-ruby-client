# junction-ruby-client

A small Ruby client for the [Junction](https://docs.junction.com) (formerly Vital) API.

## Installation

```ruby
# Gemfile — note the require override, since the gem name is hyphenated
gem 'junction-ruby-client', require: 'junction'
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

Every JSON endpoint returns a parsed `Hash` with **string keys**. The snippets
below show how to read the parts you'll typically want; see the
[Junction API reference](https://docs.junction.com) for the full response schemas.

### Create and find a user

`create`, `find`, and `find_by_client_user_id` all return the same user `Hash`:

```ruby
user = Junction::Users.create('development_1234') # POST /v2/user
user = Junction::Users.find(user['user_id']) # GET /v2/user/{user_id}
user = Junction::Users.find_by_client_user_id('development_1234') # GET /v2/user/resolve/{client_user_id}

user['user_id']        # Junction's UUID
user['client_user_id'] # Your own internal ID, e.g. "development_1234"
```

### Update user demographics

```ruby
user = Junction::Users.update_user_demographics( # PATCH /v2/user/{user_id}/info
  user['user_id'],
  first_name: 'John',
  last_name: 'Doe',
  email: 'john@email.com',
  phone_number: '+1123123123',
  gender: 'male',
  dob: '1999-01-01',
  address: {
    first_line: 'Some Street',
    state: 'AZ',
    city: 'Phoenix',
    country: 'US',
    zip: '85004'
  }
)

# Returns the updated user; the patched fields are echoed back.
user['address']['state'] # "AZ"
user['dob']              # "1999-01-01"
```

### Create and find an order

```ruby
order = Junction::Orders.create( # POST /v3/order
  user_id: user['user_id'],
  patient_details: {
    first_name: 'John',
    last_name: 'Doe',
    dob: '1999-01-01',
    gender: 'male',
    phone_number: '+13334445555',
    email: 'johndoes@example.com'
  },
  patient_address: {
    receiver_name: 'John Doe',
    first_line: '123 Main St.',
    second_line: 'Apt. 208',
    city: 'San Francisco',
    state: 'CA',
    zip: '91189',
    country: 'United States',
    phone_number: '+1123456789'
  },
  order_set: {
    lab_test_ids: ['5cdc1f4a-5b1a-4c2b-9c1f-3a4b5c6d7e8f']
  }
)

order_id = order.dig('order', 'id')
order.dig('order', 'last_event', 'status') # the latest event in the order's lifecycle, e.g. "received.at_home_phlebotomy.ordered"

order = Junction::Orders.find(order_id) # GET /v3/order/{order_id}
order.dig('last_event', 'status')       # the latest event in the order's lifecycle, e.g. "received.at_home_phlebotomy.ordered"
order['events'].map { |e| e['status'] } # full status history, oldest → newest
```

### Lab results (JSON)

```ruby
results = Junction::Orders.results(order_id) # GET /v3/order/{order_id}/result

results.dig('metadata', 'status')         # "final" once the lab has reported
results.dig('metadata', 'interpretation') # overall read, e.g. "abnormal"

results['results'].each do |marker|
  marker['name']   # "HDL Cholesterol"
  marker['result'] # "50"  — display string (e.g. "<15" for range-type markers)
  marker['type']   # "numeric"  — `result` data type
end

# Pick out the markers the lab flagged as out of range.
abnormal = results['results'].select { |m| m['interpretation'] == 'abnormal' }
```

### PDFs (requisition form and results)

Both PDF methods return the **raw PDF bytes**
as a `String`. Write them with `File.binwrite` so the binary
isn't mangled by encoding/newline translation:

```ruby
lab_req_pdf = Junction::Orders.requisition_pdf(order_id) # GET /v3/order/{order_id}/requisition/pdf
File.binwrite("tmp/requisition-#{order_id}.pdf", lab_req_pdf)

results_pdf = Junction::Orders.results_pdf(order_id)   # GET /v3/order/{order_id}/result/pdf
File.binwrite("tmp/results-#{order_id}.pdf", results_pdf)
```

### Error handling

Non-2xx responses raise `Junction::Client::RequestError`, which carries the
original `response` (`error.response.code`, `error.response.body`).

```ruby
begin
  Junction::Orders.find('does-not-exist')
rescue Junction::Client::RequestError => e
  e.response.code # => 404
  e.response.body # => raw error body from the API
end
```

## Development

```bash
bundle install
bundle exec rspec
```

To fire up a console:

```bash
# Set up your .env first (copy .env.example), and then run:
bin/console
```
