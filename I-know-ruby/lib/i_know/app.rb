# lib/i_know/app.rb
require "sinatra/base"
require "sinatra/content_for"
require "sqlite3"
require "digest"
require "dotenv/load"

module IKnow
  class App < Sinatra::Base
    helpers Sinatra::ContentFor

    configure do
      enable :sessions
      set :session_secret, ENV.fetch("SESSION_SECRET")
      set :views, File.expand_path("../../views", __dir__)
      set :public_folder, File.expand_path("../../public", __dir__)
      set :database_path, ENV.fetch("DATABASE_PATH")
    end

    before do
      @db = SQLite3::Database.new(settings.database_path)
      @db.results_as_hash = true
      @current_user = session[:user_id] ? @db.execute("SELECT * FROM users WHERE id = ?", [session[:user_id]]).first : nil
    end

    after do
      @db.close if @db
    end

    helpers do
      def hash_password(password)
        Digest::MD5.hexdigest(password)
      end

      def verify_password(stored_hash, password)
        stored_hash == hash_password(password)
      end
    end

    # Pages
    get "/" do
      q = params[:q]
      language = params[:language] || "en"
      @search_results = if q && !q.empty?
                          @db.execute("SELECT * FROM pages WHERE language = ? AND content LIKE ?", [language, "%#{q}%"])
                        else
                          []
                        end
      erb :search, locals: { search_results: @search_results, query: q }
    end

    get "/about" do
      erb :about
    end

    get "/login" do
      redirect "/" if @current_user
      erb :login
    end

    get "/register" do
      redirect "/" if @current_user
      erb :register
    end

    # API
    post "/api/login" do
      username = params["username"]
      password = params["password"]
      user = @db.execute("SELECT * FROM users WHERE username = ?", [username]).first

      if user.nil?
        @error = "Invalid username"
        erb :login
      elsif !verify_password(user["password"], password)
        @error = "Invalid password"
        erb :login
      else
        session[:user_id] = user["id"]
        redirect "/"
      end
    end

    post "/api/register" do
      if @current_user
        redirect "/"
      else
        username = params["username"]
        email = params["email"]
        password = params["password"]
        password2 = params["password2"]

        @error = if username.to_s.empty?
                   "You have to enter a username"
                 elsif email.to_s.empty? || !email.include?("@")
                   "You have to enter a valid email address"
                 elsif password.to_s.empty?
                   "You have to enter a password"
                 elsif password != password2
                   "The two passwords do not match"
                 elsif @db.execute("SELECT id FROM users WHERE username = ?", [username]).any?
                   "The username is already taken"
                 end

        if @error
          erb :register
        else
          @db.execute("INSERT INTO users (username, email, password) VALUES (?, ?, ?)", [username, email, hash_password(password)])
          session[:user_id] = @db.last_insert_row_id
          redirect "/login"
        end
      end
    end

    get "/api/logout" do
      session.clear
      redirect "/"
    end
  end
end