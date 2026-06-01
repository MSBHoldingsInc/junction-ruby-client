# frozen_string_literal: true

module Junction
  # Wraps the Junction (Vital) `/v2/user` endpoints.
  class Users
    ENDPOINT = '/v2/user'

    # Creates a Junction user.
    # https://docs.junction.com/api-reference/user/create-user
    # @param client_user_id [String] your own unique ID for the end user
    # @return [Hash]
    def self.create(client_user_id)
      Client.post(ENDPOINT, client_user_id: client_user_id)
    end

    # Partially updates a user's info (upsert).
    # https://docs.junction.com/api-reference/user/upsert-info
    # Patient name fields (first_name, last_name) must follow specific validation
    # rules due to lab restrictions:
    # https://docs.junction.com/lab/workflow/order-requirements#patient-name-validation
    # @param user_id [String]
    # @param body [Hash]
    # @return [Hash]
    def self.update_user_demographics(user_id, body)
      Client.patch("#{ENDPOINT}/#{user_id}/info", body)
    end

    # Fetches a Junction user by its Junction-generated UUID.
    # https://docs.junction.com/api-reference/user/get-user
    # @param user_id [String] the `user_id` returned from {.create}
    # @return [Hash]
    def self.find(user_id)
      Client.get("#{ENDPOINT}/#{user_id}")
    end

    # Resolves a Junction user by your own internal ID (the `client_user_id`
    # passed to #create).
    # https://docs.junction.com/api-reference/user/resolve-user
    # @param client_user_id [String]
    # @return [Hash]
    def self.find_by_client_user_id(client_user_id)
      Client.get("#{ENDPOINT}/resolve/#{client_user_id}")
    end
  end
end
