#!/usr/bin/env rake
# frozen_string_literal: true

require "bundler"

Bundler::GemHelper.install_tasks

require "rspec/core/rake_task"

task "default" => "spec"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ["--colour"]
end

require "rubocop/rake_task"

RuboCop::RakeTask.new

task "default" => "rubocop"
