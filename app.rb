require 'sinatra'
require "sinatra/reloader" if development?
require 'sinatra/cross_origin'
require 'haml'
require 'dropbox_sdk'
require 'json'
require './lib/pom_parser'
require './lib/task'
require './lib/tree_map'
require './lib/d3_writer'
require './lib/meter'

the_data = "public/liquor.json"
population_data = "public/population.json"
brushing_data = "public/brushing.json"
bars_data = "public/bars.json"

configure do
  enable :cross_origin
end

enable :sessions

APP_KEY = 'hellooooo'
APP_SECRET = 'dolly helloooo'

# get '/' do
#   "HELLO!"
# end

get '/' do
  pom_sheet_path = File.join(Dir.home,"pomsheet.txt")

  poms_string = File.readlines(pom_sheet_path).join

  poms_input = File.open(pom_sheet_path,"r")
  pom_parser = PomParser.new(poms_input)  
  
  meter = Meter.new(pom_parser)

  haml :index, :locals => {pom_sheet: poms_string, meter: meter.poms_left}
end

get '/test' do
  haml :test
end

get '/login' do
  dropbox_session = DropboxSession.new(APP_KEY,APP_SECRET)
  dropbox_session.get_request_token
  session[:dropbox] = dropbox_session.serialize()

  redirect authorize_url = dropbox_session.get_authorize_url(url("/pomsheet"))
end

get '/pomsheet' do
  dropbox_session = DropboxSession::deserialize(session[:dropbox])
  client = DropboxClient.new(dropbox_session,:dropbox)
  pom_sheet = client.get_file('/2014 Pomodoro.txt')
  "<pre>" + pom_sheet + "</pre>"
end

get '/pomtree' do
  # response.headers["Access-Control-Allow-Origin"] = "*"
  content_type :json
  File.read(the_data)
end

get '/population' do
  content_type :json
  File.read(population_data)
end 

get '/brushing' do
  content_type :json
  File.read(brushing_data)
end

get '/bars' do
  content_type :json
  File.read(bars_data)
end

get '/bars_mine' do
  pom_sheet_path = "/home/salmonax/Dropbox/2014 Pomodoro.txt"
  poms_input = File.open(pom_sheet_path,"r")
  pom_parser = PomParser.new(poms_input)  
  d3_writer = D3writer.new(pom_parser)
  content_type :json
  d3_writer.write_area_chart
end

get '/eureka' do
  pom_sheet_path = "/home/salmonax/Dropbox/2014 Pomodoro.txt"
  poms_input = File.open(pom_sheet_path,"r")
  pom_parser = PomParser.new(poms_input)
  treemap = Treemap.new(pom_parser.full)
  content_type :json
  treemap.full.to_json
end

get '/d3' do
  pom_sheet_path = "/home/salmonax/Dropbox/2014 Pomodoro.txt"
  poms_input = File.open(pom_sheet_path,"r")
  pom_parser = PomParser.new(poms_input)  
  d3_writer = D3writer.new(pom_parser)
  content_type :json
  d3_writer.write
end

get '/logout' do
  session[:dropbox] = nil
  redirect '/'
end
