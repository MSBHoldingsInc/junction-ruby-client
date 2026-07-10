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

### Appointment Scheduling

Patients can find a time, book, reschedule, and cancel a lab appointment
entirely in-app — no hand-off to the lab's scheduler. This is only available
for PSCs whose coverage capabilities include `appointment_scheduling_via_junction`
(currently Quest only). Locations that expose only `appointment_scheduling_with_lab`
(e.g. Sonora Quest in Arizona) can't be booked through Junction — link the
patient out to the lab's own scheduler instead. The order/requisition is still
created via Junction and results flow back the same way; only the time selection
happens on the lab's side. See the
[capability docs](https://docs.junction.com/lab/overview/locations#appointment-scheduling-capability).

```ruby
# Find open slots — by ZIP (returns up to 3 nearby PSCs) or by specific site_codes
# (from Junction::PatientServiceCenters.near). Each location carries its own
# iana_timezone; slot start/end times are UTC.
availability = Junction::Appointments.availability( # POST /v3/order/psc/appointment/availability
  lab: 'quest',
  zip_code: '85004',
  start_date: '2026-06-15',
  radius: 50 # one of 10, 20, 25, 50, 100 (defaults to 25)
)

slot = availability['slots'].first['slots'].first
booking_key = slot['booking_key']

# Book the chosen slot for an order
appointment = Junction::Appointments.book( # POST /v3/order/{order_id}/psc/appointment/book
  order_id,
  booking_key: booking_key,
  appointment_notes: 'wheelchair access' # optional
)
appointment['id']          # the appointment's Junction UUID
appointment['external_id'] # the lab's own reference (e.g. Quest's 6-letter code), shown to the patient
appointment['status']      # "confirmed"

# Retrieve the appointment for an order
Junction::Appointments.find(order_id) # GET /v3/order/{order_id}/psc/appointment

# Reschedule to a new slot (booking_key from another availability lookup)
Junction::Appointments.reschedule(order_id, booking_key: 'another-booking-key') # PATCH .../reschedule

# Cancel — pick a reason id from the cancellation reasons list
reasons = Junction::Appointments.cancellation_reasons # GET /v3/order/psc/appointment/cancellation-reasons
reasons.first['id']            # pass this as cancellation_reason_id
reasons.first['is_refundable'] # whether cancelling for this reason is refundable

Junction::Appointments.cancel( # PATCH /v3/order/{order_id}/psc/appointment/cancel
  order_id,
  cancellation_reason_id: reasons.first['id'],
  note: 'patient moved out of state' # optional
)
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

### Lab Test Markers

List the markers (biomarkers) a lab test measures.

```ruby
markers = Junction::LabTests.markers('lab_test_id') # GET /v3/lab_tests/{lab_test_id}/markers
markers.first =>
{
  "id" => 3188,
  "name" => "IGF-1, LC/MS",
  "slug" => "igf-1-lc-ms",
  "description" => "IGF-1, LC/MS",
  "lab_id" => 7,
  "provider_id" => "16293",
  "type" => "panel",
  "unit" => nil,
  "price" => "18.00",
  "aoe" => nil,
  "a_la_carte_enabled" => true,
  "common_tat_days" => 9,
  "worst_case_tat_days" => 13,
  "is_orderable" => true,
  "expected_results" => [
    {
      "id" => 109648,
      "name" => "Igf 1, Lc/Ms",
      "slug" => "igf-1-lc-ms",
      "lab_id" => 7,
      "provider_id" => "86006200",
      "required" => true,
      "loinc" => {
        "id" => 15678,
        "name" => "Insulin-like growth factor-I [Mass/Vol]",
        "slug" => "insulin-like-growth-factor-i-mass-vol",
        "code" => "2484-4",
        "unit" => "ng/mL"
      }
    },
    {
      "id" => 109649,
      "name" => "Z Score (Male)",
      "slug" => "z-score-male",
      "lab_id" => 7,
      "provider_id" => "86006684",
      "required" => false,
      "loinc" => {
        "id" => 48476,
        "name" => "Insulin-like growth factor-I [Z-score]",
        "slug" => "insulin-like-growth-factor-i-z-score",
        "code" => "73561-3",
        "unit" => "{Z-score}"
      }
    },
    {
      "id" => 109650,
      "name" => "Z Score (Female)",
      "slug" => "z-score-female",
      "lab_id" => 7,
      "provider_id" => "86006201",
      "required" => false,
      "loinc" => {
        "id" => 48476,
        "name" => "Insulin-like growth factor-I [Z-score]",
        "slug" => "insulin-like-growth-factor-i-z-score",
        "code" => "73561-3",
        "unit" => "{Z-score}"
      }
    }
  ]
}
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
