require './lib/modules/hash_magic'
require './lib/pom_parser'
require './lib/task'
require './lib/tree_map'
require 'pp'

pom_sheet_path = "/home/salmonax/Dropbox/2014 Pomodoro.txt"
poms_input = File.open(pom_sheet_path,"r")
pom_parser = PomParser.new(poms_input)

# pp pom_parser.full[:books]