require './lib/modules/hash_magic'
require './lib/pom_parser'
require './lib/task'
require './lib/tree_map'
require './lib/csv_writer'
require 'date'
require 'pp'

pom_sheet_path = "/home/salmonax/Dropbox/2014 Pomodoro.txt"
poms_input = File.open(pom_sheet_path,"r")
pom_parser = PomParser.new(poms_input)

csv_writer = CSVwriter.new(pom_parser)
 

csv_for_spreadsheet = "/home/salmonax/@work/naomi/for_spreadsheet.csv"
spreadsheet_output = File.open(csv_for_spreadsheet,"w")

csv_writer.write_for_days(spreadsheet_output)