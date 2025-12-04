# frozen_string_literal: true

# Authentication route definitions.
module AuthRoutes
  def self.registered(app)
    # Register instance helpers once (no nested defs).
    app.helpers AuthHelpers

    register_login_routes(app)
    register_register_routes(app)
    register_logout_routes(app)
  end

  # -------------------------
  # LOGIN
  # -------------------------
  def self.register_login_routes(app)
    app.get '/login' do
      redirect '/' if @current_user
      erb :login
    end

    app.post '/api/login' do
      process_login_request(params)
    end
  end

  # -------------------------
  # REGISTER
  # -------------------------
  def self.register_register_routes(app)
    app.get '/register' do
      redirect '/' if @current_user
      erb :register
    end

    app.post '/api/register' do
      process_register_request(params)
    end
  end

  # -------------------------
  # LOGOUT
  # -------------------------
  def self.register_logout_routes(app)
    app.get '/api/logout' do
      session.clear
      redirect '/'
    end
  end

  # Helper methods are defined in this module and registered as Sinatra helpers.
  module AuthHelpers
    # LOGIN helpers
    def process_login_request(params)
      username, password = extract_login_params(params)
      user               = find_user(username)
      error              = login_error(user, password)

      error ? render_login_error(error) : finalize_login(user)
    end

    def extract_login_params(params)
      [params['username'], params['password']]
    end

    def find_user(username)
      @db.execute('SELECT * FROM users WHERE username = ?', [username]).first
    end

    def login_error(user, password)
      return 'Invalid username' if user.nil?
      return 'Invalid password' unless verify_password(user['password'], password)

      nil
    end

    def render_login_error(error)
      @error = error
      erb :login
    end

    def finalize_login(user)
      session[:user_id] = user['id']
      redirect '/'
    end

    # REGISTER helpers
    def process_register_request(params)
      return redirect '/' if @current_user

      username, email, password, password2 = extract_register_params(params)
      error = registration_error(username, email, password, password2)

      error ? render_register_error(error) : finalize_register(username, email, password)
    end

    def extract_register_params(params)
      [
        params['username'],
        params['email'],
        params['password'],
        params['password2']
      ]
    end

    def render_register_error(error)
      @error = error
      erb :register
    end

    def finalize_register(username, email, password)
      @db.execute(
        'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
        [username, email, hash_password(password)]
      )
      session[:user_id] = @db.last_insert_row_id
      redirect '/login'
    end

    def registration_error(username, email, password, password2)
      return 'You have to enter a username' if username.to_s.empty?
      return 'You have to enter a valid email address' if email.to_s.empty? || !email.include?('@')
      return 'You have to enter a password' if password.to_s.empty?
      return 'The two passwords do not match' if password != password2
      return 'The username is already taken' if @db.execute('SELECT id FROM users WHERE username = ?', [username]).any?

      nil
    end
  end
end
