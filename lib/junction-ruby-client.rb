# frozen_string_literal: true

# Shim so Bundler's default `require "junction-ruby-client"` (hyphen -> the gem
# name) loads the real entrypoint at lib/junction.rb.
require 'junction'
