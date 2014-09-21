require 'sinatra'
require "sinatra/reloader" if development?
require 'sinatra/cross_origin' #to let codepen pull localhost json
require 'haml'
require 'dropbox_sdk'
require 'json'

require './lib/modules/hash_magic'

require './lib/pom_parser'
require './lib/task'
require './lib/tree_map'
require './lib/d3_writer'
require './lib/meter'

also_reload './lib/pom_parser.rb'
also_reload './lib/d3_writer.rb'

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

before do
  if @pom_sheet_path.nil?
    @pom_sheet_path = File.join(Dir.home,"pomsheet.txt")
    @poms_input = File.open(@pom_sheet_path,"r")
    @pom_parser = PomParser.new(@poms_input)

    @meter = Meter.new(@pom_parser)

    @d3_writer = D3writer.new(@pom_parser)
    @treemap = Treemap.new(@pom_parser.full)
    @monthlies = "GO AWAY!"
  end
end

# before '/d3/*' do
#   content_type :json
# end

get '/' do
  poms_string = File.readlines(@pom_sheet_path).join ## Note: awful, awful way to do this
  haml :index, :locals => {pom_sheet: poms_string, meter: @meter.poms_left, monthlies: @pom_parser.targets}
end

get '/highstock' do
  haml :highstock
end

get '/treemap' do
  @pom_parser = PomParser.new(@poms_input, last: 10)
  @treemap = Treemap.new(@pom_parser.full[:categories])

  poms_string = File.readlines(@pom_sheet_path).join ## Note: awful, awful way to do this
  haml :treemap, :locals => {pom_sheet: poms_string, meter: @meter.poms_left, monthlies: @pom_parser.targets}
end

get '/highstock.json' do
  content_type :json
  @d3_writer.write_highstock
end

get '/highstock2.json' do
  content_type :json
  @d3_writer.write_highstock('output')
end

get '/dump' do
  dump = @pom_parser.full[:books]
  haml :dump, :locals => {dump: dump }
end

get '/d3/area_chart' do
  @d3_writer.write_area_chart
end

get '/d3/area_chart2' do
  @d3_writer.write_area_chart2
end

get '/d3/treemap' do
  @treemap.full.to_json
end

get '/d3/treemap2' do
  @pom_sheet_path = File.join(Dir.home,"pomsheet.txt")
  @poms_input = File.open(@pom_sheet_path,"r")
  @pom_parser2 = PomParser.new(@poms_input, last: 40)
  @treemap = Treemap.new(@pom_parser2.full)
  @treemap.full.to_json
end

##

get '/d3/heatmap' do
  @d3_writer.write
end

get '/heatmap' do
  haml :heatmap
end

## BEGIN all Dropbox-related stuff

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

get '/logout' do
  session[:dropbox] = nil
  redirect '/'
end

### BEGIN random tester stuff

get '/timer' do 
  haml :timer
end


get '/test' do
  haml :test
end


get '/pomtree' do
  # response.headers["Access-Control-Allow-Origin"] = "*"
  content_type :json
  File.read(the_data)
end

# get '/monthlies' do
#   content_type :json
#   File.
# end

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
