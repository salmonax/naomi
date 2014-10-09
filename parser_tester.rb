require './lib/modules/hash_magic'

require './lib/pom_parser'
require './lib/task'
require './lib/tree_map'
require './lib/csv_writer'
require './lib/d3_writer'
require './lib/meter'


require 'json'
require 'date'
# require 'yomu'
require 'pp'
# require 'fuzzy_match'
# require 'openlibrary'

pom_sheet_path = "/home/salmonax/Dropbox/2014 Pomodoro.txt"

csv_output_path = "/home/salmonax/@work/naomi/output.csv"
d3_output_path = "/home/salmonax/@work/naomi/d3_data.json"

csv_output = File.open(csv_output_path,"w")
d3_output = File.open(d3_output_path,"w")

poms_input = File.open(pom_sheet_path,"r")
pom_parser = PomParser.new(poms_input)

csv_writer = CSVwriter.new(pom_parser)
d3_writer = D3writer.new(pom_parser)

class PomJuicer
  def initialize(parser)
    @parser = parser
#memo (Bitbucket SSH: Host/Identityfile to ~/.ssh, id_rsa.pub to repo)
#memo   (ssh -T git@bitbucket.org, switch project/.git/config url to ssh verison)
  end
end

class TagCounter
  def initialize(parser)
    @parser = parser
    @daily_tally = []
  end
end

csv_writer.write(csv_output)
# d3_writer.write_file(d3_output)
# 

# meter = Meter.new(pom_parser)

# p meter.poms_this_month
# p meter.poms_left







# ---- Journal Side-Project Stuff ----
# journal_loc = "/home/salmonax/Dropbox/Journal 2013.doc"
# journal = Yomu.new(journal_loc)
# p journal.text.scan(/January\s\d*\,.*\n/).each { |line| p line }

# pp pom_parser.tag_labels

# pp pom_parser.days
# pp pom_parser.full 

treemap = Treemap.new(pom_parser.full)
treemap.full[:categories]

# pom_sheet_path = "/home/salmonax/Dropbox/2014 Pomodoro.txt"

category_definitions = ["PomParsley: Categories: Build Hash", "PomParsley: Refactor"]
flat = { "PomParsley" => 10, "Categories" => 5, "Refactor" => 4, "Codepen" => 15, "Books" => 5}
nested = { "PomParsley" => { "Categories" => {"Build Hash" => 0}, "Refactor" => 0}, "Codepen" => 0} 

#PomParsley
#  Categories
#    Build Hash
#  Refactor
#CodePen

to_be_nested = {}
# 

# puts "CORRECT:    #{nestle_flat_hash(flat,nested)}"
# puts "FROM ARRAY: #{nestle_array(category_definitions,to_be_nested)}"


pp D3writer.new(pom_parser).write_highstock