# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(spec: :mysql)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[rubocop spec]

desc 'Ensure MySQL is available'
task :mysql do
  sh 'docker compose up --detach mysql &> /dev/null'
  catch :ready do
    loop do
      sh 'docker compose run --rm mysql mysql -h mysql -e "SELECT 1" &> /dev/null' do |ok|
        ok ? throw(:ready) : sleep(1)
      end
    end
  end
end
