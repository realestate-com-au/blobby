#!/usr/bin/env rake

require "bundler"

Bundler::GemHelper.install_tasks

require "rspec/core/rake_task"

task "default" => "spec"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ["--colour"]
end
