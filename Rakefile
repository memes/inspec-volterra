# frozen_string_literal: true

require 'rake/testtask'
require 'rubocop/rake_task'

desc 'Run rubocop linter'
task :rubocop do
  RuboCop::RakeTask.new do |task|
    task.requires << 'rubocop-rake'
    task.options += ['--display-cop-names', '--no-color', '--parallel']
  end
end

task default: ['test:check']

namespace :test do
  desc 'Run inspec check for this extension'
  task :check do
    cwd = File.join(File.dirname(__FILE__))
    sh("bundle exec inspec check #{cwd} --chef-license=accept-silent")
  end

  desc 'Run default inspec integration tests'
  task :integration do
    cwd = File.join(File.dirname(__FILE__))
    # rubocop:disable Layout/LineLength
    sh("bundle exec inspec exec #{cwd}/test/integration/default --chef-license=accept-silent; if [$? -eq 0] || [$? -eq 101 ]; then exit 0; else exit 1; fi")
    # rubocop:enable Layout/LineLength
  end
end

desc 'Perform linting and run integration tests'
task :all do
  Rake::Task['rubocop'].execute
  Rake::Task['test:check'].execute
  Rake::Task['test:integration'].execute
end
