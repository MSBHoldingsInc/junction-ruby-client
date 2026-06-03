# junction-ruby-client

A small Ruby client for the [Junction](https://docs.junction.com) (formerly Vital) API.

## Installation

This is a private, unpublished gem — install it directly from GitHub. Add to
your Gemfile:

```ruby
# Track the HEAD of the default branch (main)
gem 'junction-ruby-client', git: 'https://github.com/MSBHoldingsInc/junction-ruby-client', require: 'junction'
```

Or pin to a specific ref for reproducible installs — Bundler locks to it until
you explicitly change it, so `bundle update` won't pull newer commits. Use one of:

```ruby
# branch: — follow the tip of a branch
gem 'junction-ruby-client', git: 'https://github.com/MSBHoldingsInc/junction-ruby-client', branch: 'main', require: 'junction'
# tag: — lock to a release tag
gem 'junction-ruby-client', git: 'https://github.com/MSBHoldingsInc/junction-ruby-client', tag: 'v0.3.0', require: 'junction'
# ref: — lock to an exact commit SHA
gem 'junction-ruby-client', git: 'https://github.com/MSBHoldingsInc/junction-ruby-client', ref: 'abc1234', require: 'junction'
```

## Configuration

Add an initializer `config/initializers/junction.rb` with a `#configure` block:

```ruby
Junction.configure do |c|
  c.api_key  = Rails.application.credentials.dig(:junction, :api_key) || ENV.fetch('JUNCTION_API_KEY')
  c.base_uri = Rails.env.production? ? 'https://api.us.junction.com'
                                     : 'https://api.sandbox.us.junction.com'
end
```

### Options

| Option     | Default                                  | Notes                                            |
|------------|------------------------------------------|--------------------------------------------------|
| `api_key`  | `nil`                                    | Sent as the `x-vital-api-key` header.            |
| `base_uri` | `https://api.sandbox.us.junction.com`    | Region/env host (`api.us` / `api.eu`, sandbox or prod). |

## Usage

Every JSON endpoint returns a parsed `Hash` with **string keys**. The snippets
below show how to read the parts you'll typically want; see the
[Junction API reference](https://docs.junction.com) for the full response schemas.

### Create and Find a User

`create`, `find`, and `find_by_client_user_id` all return the same user `Hash`:

```ruby
user = Junction::Users.create('development_1234') # POST /v2/user
user = Junction::Users.find(user['user_id']) # GET /v2/user/{user_id}
user = Junction::Users.find_by_client_user_id('development_1234') # GET /v2/user/resolve/{client_user_id}

user['user_id']        # Junction's UUID
user['client_user_id'] # Your own internal ID, e.g. "development_1234"
```

### Update User Demographics

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

### Create and Find an Order

> **Note:** `POST /v3/order` upserts the Junction **User** record. The `patient_details`
> and `patient_address` sent with each order creation will update that user on Junction's side,
> so there's no need for a separate "update user" call.

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

### Patient Service Centers

Find where a patient can get tested — by area, by lab, or for an existing order.
Each call takes an optional `radius` in miles (defaults to `25`).

```ruby
# Lab/area coverage for a ZIP — keyed by lab slug, each value carrying a lab_id.
Junction::PatientServiceCenters.coverage('85004') # GET /v3/order/area/info

# Patient service centers near a ZIP for a specific lab (widen the search to 100 miles).
Junction::PatientServiceCenters.near('85004', lab_id: 4, radius: 100) # GET /v3/order/psc/info

# Patient service centers available for an existing order.
Junction::PatientServiceCenters.for_order(order_id) # GET /v3/order/{order_id}/psc/info
```

### Lab Results

```ruby
results = Junction::LabResults.find(order_id) # GET /v3/order/{order_id}/result

results.dig('metadata', 'status')         # "final" once the lab has reported
results.dig('metadata', 'interpretation') # overall read, e.g. "abnormal"

results['results'].each do |marker|
  marker['name']   # "HDL Cholesterol"
  marker['result'] # "50"  — display string (e.g. "<15" for range-type markers)
  marker['type']   # "numeric"  — `result` data type
end

# Pick out the markers the lab flagged as out of range
abnormal = results['results'].select { |m| m['interpretation'] == 'abnormal' }

# Get lab results PDF and write it to a file
lab_results_pdf = Junction::LabResults.pdf(order_id) # GET /v3/order/{order_id}/result/pdf
File.binwrite("tmp/lab-results-#{order_id}.pdf", lab_results_pdf)
```

### Lab Requisition PDF

```ruby
lab_req_pdf = Junction::Orders.requisition_pdf(order_id) # GET /v3/order/{order_id}/requisition/pdf
File.binwrite("tmp/lab-requisition-#{order_id}.pdf", lab_req_pdf)
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

Requires Ruby >= 3.0 (see `.ruby-version`).

```bash
bundle install         # install dependencies
bundle exec rake setup # install the git pre-commit hook (one-time, after cloning)
bundle exec rake       # run RuboCop + the full test suite (the default task)
```

Run the linter or the suite on their own:

```bash
bundle exec rubocop # lint (add -a to safe-autocorrect)
bundle exec rspec   # tests
```

A pre-commit hook (installed by `rake setup` via `core.hooksPath`) runs RuboCop
on staged Ruby files, auto-fixes safe offenses and re-stages them, and blocks
the commit if anything remains that can't be corrected automatically.

To open a console with the gem loaded, copy `.env.example` to `.env`, fill in
your sandbox credentials, then run `bin/console`:

```bash
cp .env.example .env # then edit .env and set JUNCTION_API_KEY
bin/console
```
