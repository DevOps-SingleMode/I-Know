# frozen_string_literal: true

# lib/i_know/app.rb
require 'sinatra/base'
require 'sinatra/content_for'
require 'sqlite3'
require 'digest'
require 'dotenv/load'
require 'json'
require 'httparty'

require_relative 'routes/pages'
require_relative 'routes/auth'
require_relative 'routes/weather'

module IKnow
  # The main Sinatra application class handling all routes and logic.
  # @example Running the app: ruby app.rb
  class App < Sinatra::Base
    helpers Sinatra::ContentFor

    configure do
      enable :sessions
      set :session_secret, ENV.fetch('SESSION_SECRET')
      set :views, File.expand_path('../../views', __dir__)
      set :public_folder, File.expand_path('../../public', __dir__)
      set :database_path, ENV['DATABASE'] || ENV.fetch('DATABASE_PATH')
      set :bind, '0.0.0.0'
    end

    before do
      @db = SQLite3::Database.new(settings.database_path)
      @db.results_as_hash = true
      @current_user = if session[:user_id]
                        @db.execute('SELECT * FROM users WHERE id = ?',
                                    [session[:user_id]]).first
                      end
    end

    after do
      @db&.close
    end

    helpers do
      def hash_password(password)
        Digest::MD5.hexdigest(password)
      end

      def verify_password?(stored_hash, password)
        stored_hash == hash_password(password)
      end
    end

    def self.init_db
      return unless ENV['RACK_ENV'] == 'test'

      schema_path = File.expand_path('../../db/schema.sql', __dir__)
      db_path = ENV['DATABASE'] || settings.database_path

      # Create a fresh DB file for the test run
      FileUtils.rm_f(db_path)

      db = SQLite3::Database.new(db_path)
      db.execute_batch(File.read(schema_path))
      db.close
    end

    register PagesRoutes
    register AuthRoutes
    register WeatherRoutes
  end
end
