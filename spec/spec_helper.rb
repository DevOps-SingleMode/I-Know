# frozen_string_literal: true

require 'simplecov'
require 'simplecov-json'
SimpleCov.start do
  enable_coverage :branch
  add_filter '/spec/'

  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ])

end

ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'rspec'
require_relative '../lib/i_know/app' # adjust if path differs

RSpec.configure do |config|
  config.include Rack::Test::Methods

  def app
    IKnow::App
  end
end
