# frozen_string_literal: true

# Static and search page routes.
module PagesRoutes
  def self.registered(app)
    app.helpers PagesHelpers

    register_search_routes(app)
    register_static_routes(app)
  end

  # -------------------------
  # SEARCH
  # -------------------------
  def self.register_search_routes(app)
    app.get '/' do
      q, language = extract_search_params(params)
      results     = search_pages(q, language)

      erb :search, locals: { search_results: results, query: q }
    end
  end

  # -------------------------
  # STATIC
  # -------------------------
  def self.register_static_routes(app)
    app.get('/about') { erb :about }
    app.get('/doc')   { erb :doc }

    app.get '/doc/openapi.yml' do
      send_file File.expand_path('../doc/openapi.yml', __dir__)
    end
  end

  # -------------------------
  # HELPERS
  # -------------------------
  module PagesHelpers
    def extract_search_params(params)
      [
        params[:q],
        params[:language] || 'en'
      ]
    end

    def search_pages(query, language)
      return [] if query.nil? || query.empty?

      @db.execute(
        'SELECT * FROM pages WHERE language = ? AND content LIKE ?',
        [language, "%#{query}%"]
      )
    end
  end
end
