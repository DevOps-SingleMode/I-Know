#lib/i_know/app.rb
require "sinatra/base"

module IKnow
  class App < Sinatra::Base
    get "/" do
      "Hello world from IKnow!"
    end
  end
end
