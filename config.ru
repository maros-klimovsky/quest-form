require './quest_web'
Slim::Engine.default_options[:pretty] = true
run Sinatra::Application
