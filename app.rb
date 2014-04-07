require 'sinatra'
require "sinatra/reloader" if development?
require 'haml'
require 'dropbox_sdk'
require 'json'


enable :sessions

APP_KEY = 'tjs38tromefvyun'
APP_SECRET = 'qun1od558x53qd8'

# get '/' do
#   "HELLO!"
# end

get '/the_dropbox_path' do
  dropbox_session = DropboxSession.new(APP_KEY,APP_SECRET)
  dropbox_session.get_request_token
  session[:dropbox] = dropbox_session.serialize()

  redirect authorize_url = dropbox_session.get_authorize_url(url("/stuff"))
end

get '/stuff' do
  dropbox_session = DropboxSession::deserialize(session[:dropbox])
  client = DropboxClient.new(dropbox_session,:dropbox)
  pom_sheet = client.get_file('/2014 Pomodoro.txt')
  "<pre>" + pom_sheet + "</pre>"

end

get '/treemap' do
  content_type :json
  File.read("public/liquor.json")
end

get '/logout' do
  session[:dropbox] = nil
  redirect '/'
end
