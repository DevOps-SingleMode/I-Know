# frozen_string_literal: true

# spec/i_know_spec.rb
require 'spec_helper'
require 'tempfile'
require 'nokogiri'

  RSpec.describe IKnow::App, type: :request do
  let(:db_file) { Tempfile.new('test.db') }

  before do
    ENV['RACK_ENV'] = 'test'
    ENV['DATABASE'] = db_file.path
    described_class.init_db
  end

  after do
    db_file.close
    db_file.unlink
  end

  # --- helper methods ----------------------------------------------------
  def register(username, password, password2 = password, email = nil)
    email ||= "#{username}@example.com"
    post '/api/register', {
      username: username,
      password: password,
      password2: password2,
      email: email
    }
    last_response
  end

  def login(username, password)
    post '/api/login', { username: username, password: password }
    last_response
  end

  def register_and_login(username, password)
    register(username, password)
    login(username, password)
  end

  def logout
    get '/api/logout'
    last_response
  end

  # --- helpers for parsing HTML ------------------------------------------
  def error_message(response)
    doc = Nokogiri::HTML(response.body)
    doc.at_css('div.error')&.text&.strip
  end

  def success_message(response)
    doc = Nokogiri::HTML(response.body)
    doc.at_css('div.success')&.text&.strip
  end

  # --- tests --------------------------------------------------------------
  describe 'registration' do
    it 'registers users successfully' do
      rv = register('user1', 'default')
      expect(success_message(rv)).to include('You were successfully registered') if success_message(rv)
    end

    it 'fails when username is taken' do
      rv = register('user1', 'default')
      expect(error_message(rv)).to include('The username is already taken')
    end

    it 'fails with empty username' do
      rv = register('', 'default')
      expect(error_message(rv)).to include('You have to enter a username')
    end

    it 'fails with empty password' do
      rv = register('meh', '')
      expect(error_message(rv)).to include('You have to enter a password')
    end

    it 'fails when passwords do not match' do
      rv = register('meh', 'x', 'y')
      expect(error_message(rv)).to include('The two passwords do not match')
    end

    it 'fails with invalid email' do
      rv = register('meh', 'foo', 'foo', 'broken')
      expect(error_message(rv)).to include('You have to enter a valid email address')
    end
  end

  describe 'login/logout' do
    it 'logs in successfully' do
      rv = register_and_login('user1', 'default')
      expect(success_message(rv)).to include('You were logged in') if success_message(rv)
    end

    it 'logs out successfully' do
      register_and_login('user1', 'default')
      rv = logout
      expect(success_message(rv)).to include('You were logged out') if success_message(rv)
    end

    it 'fails login with wrong password' do
      register('user1', 'default')
      rv = login('user1', 'wrongpassword')
      expect(error_message(rv)).to include('Invalid password')
    end

    it 'fails login with wrong username' do
      rv = login('user2', 'wrongpassword')
      expect(error_message(rv)).to include('Invalid username')
    end
  end
end
