require './lib/pom_parser'
require './lib/task'
require './lib/tree_map'
require './lib/csv_writer'
require './lib/d3_writer'
require './lib/meter'
require 'json'
require 'yomu'
require 'pp'
require 'fuzzy_match'
# require 'openlibrary'

pom_sheet_path = "/home/salmonax/Dropbox/2014 Pomodoro.txt"

csv_output_path = "/home/salmonax/@work/naomi/output.csv"
# d3_output_path = "/home/salmonax/@work/pom_parsley/d3_data.json"

csv_output = File.open(csv_output_path,"w")
# d3_output = File.open(d3_output_path,"w")

poms_input = File.open(pom_sheet_path,"r")
pom_parser = PomParser.new(poms_input)

csv_writer = CSVwriter.new(pom_parser)
d3_writer = D3writer.new(pom_parser)

class PomJuicer 
  def initialize(parser)
    @parser = parser
  end
end

class TagCounter
  def initialize(parser)
    @parser = parser
    @daily_tally = []
  end
end

# csv_writer.write(csv_output)
# d3_writer.write_file(d3_output)


# meter = Meter.new(pom_parser)

# p meter.poms_this_month
# p meter.poms_left




# ---- Journal Side-Project Stuff ----
# journal_loc = "/home/salmonax/Dropbox/Journal 2013.doc"
# journal = Yomu.new(journal_loc)
# p journal.text.scan(/January\s\d*\,.*\n/).each { |line| p line }


pp pom_parser.full[:books]
# treemap = Treemap.new(pom_parser.full)
# pp treemap.full

# pom_sheet_path = "/home/salmonax/Dropbox/2014 Pomodoro.txt"