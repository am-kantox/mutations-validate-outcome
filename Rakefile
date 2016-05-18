# encoding: UTF-8
require 'rubygems'

require 'bundler'
require 'bundler/setup'
require 'bundler/gem_tasks'

require 'rake/testtask'

begin
  Bundler.setup(:default, :development, :test)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end

desc 'Tests'
Rake::TestTask.new(:test) do |test|
  test.libs << 'spec'
  test.warning = false # Wow that outputs a lot of shit
  # test.verbose = true
  test.pattern = 'spec/**/*_spec.rb'
end

task default: :test
