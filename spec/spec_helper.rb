# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
  add_filter '/spec/'
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
