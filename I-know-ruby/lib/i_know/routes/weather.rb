# frozen_string_literal: true

CACHE_TTL = 600
# Routes and helpers for weather pages and API endpoints.
module WeatherRoutes
  def self.registered(app)
    app.helpers WeatherHelpers

    register_weather_page(app)
    register_weather_api(app)
  end

  # -------------------------
  # PAGE
  # -------------------------
  def self.register_weather_page(app)
    app.get '/weather' do
      data = fetch_internal_weather
      render_weather_page(data)
    end
  end

  # -------------------------
  # API
  # -------------------------
  def self.register_weather_api(app)
    app.get '/api/weather' do
      content_type :json
      { data: cached_weather_data }.to_json
    end
  end

  # -------------------------
  # HELPERS
  # -------------------------
  module WeatherHelpers
    def cache_store
      @cache_store ||= { data: nil, timestamp: nil }
    end

    # ------------ INTERNAL ------------
    def fetch_internal_weather
      response = HTTParty.get('http://localhost:4567/api/weather')
      response.parsed_response['data']
    end

    def render_weather_page(data)
      if valid_weather?(data)
        @weather = data
        @temp    = extract_temp(data)
      else
        @weather = nil
        @temp    = nil
        @error_message = extract_error_message(data)
      end

      erb :weather
    end

    def valid_weather?(data)
      data && data['main']
    end

    def extract_temp(data)
      data['main']['temp']
    end

    def extract_error_message(data)
      data ? data['message'] : 'Ingen data modtaget'
    end

    # ------------ EXTERNAL + CACHE ------------
    def cached_weather_data
      fresh? ? cache_store[:data] : fetch_and_store_weather
    end

    def fresh?
      cache_store[:data] &&
        (Time.now - cache_store[:timestamp] < CACHE_TTL)
    end

    def fetch_and_store_weather
      data = request_weather_api
      update_cache(data)
      data
    end

    def request_weather_api
      api_key = ENV.fetch('WEATHER_API_KEY', nil)
      response = HTTParty.get(
        'https://api.openweathermap.org/data/2.5/weather',
        query: {
          q: 'Copenhagen',
          units: 'metric',
          appid: api_key
        }
      )
      response.parsed_response
    end

    def update_cache(data)
      cache_store[:data]      = data
      cache_store[:timestamp] = Time.now
    end
  end
end
