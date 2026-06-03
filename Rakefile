# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

desc 'Install the git pre-commit hook (points core.hooksPath at .githooks)'
task :setup do
  sh 'git config core.hooksPath .githooks'
  puts 'Git hooks installed: core.hooksPath -> .githooks'
end

task default: %i[rubocop spec]
