class CSVwriter
  def initialize(parser,output=nil)
    @parser = parser
    @header = "Date;Start Time;End Time;Tags;Category;Task;Poms"
    @header_for_days = "Day;Date;Pom Total;$$ Pom;$ Pom;$$ Collected;R Pom;& Pom;Non-work income;Month;RR Pom;Flip;W Pom;WW Pom;H Pom;HH Pom\r\n"

  end

  def write(output)
    @output = output
    @output.puts(@header)
    @parser.tasks.each { |task| write_line(task) }
  end

  def write_for_days(output)
    @output = output
    @output.puts(@header_for_days.gsub(';',','))
    pp @header_for_days
    # pp @parser.days.sort_by{|k,v| k}
    @parser.days.sort_by{|k,v| k.split('/').map { |element| element.rjust(2,"0") }.join('/') }.each do |day|
      # date = day.first.split('/').map { |element| element.rjust(2,"0") }.join('/')
      date = day.first
      month = day.first.split('/').first.to_i
      poms = day.last[:poms]
      tags = day.last[:tags]
      r_total = (tags['R'].to_i + tags['RR'].to_i)
      r_total = nil if r_total == 0
      w_total = (tags['W'].to_i + tags ['WW'].to_i)
      w_total = nil if w_total == 0
      h_total = (tags['H'].to_i + tags['HH'].to_i)
      h_total = nil if h_total == 0
      # pp @header_for_days
      @output.puts ",#{date},#{poms},#{tags['$$']},#{tags['$']},,#{r_total},#{tags['&']},,#{month},#{tags['RR']},,#{w_total},#{tags['WW']},#{h_total},#{tags['HH']},\r\n"
    end
  end

  private

  def write_line(task)
    @output.puts "#{task.date};#{task.start_time};"\
                  "#{task.end_time};#{task.tags.join};#{task.category};"\
                  "\"#{task.task}\";#{task.poms};\r\n"

  end

end

# require './modules/hash_magic'
# require './pom_parser'
# require './task'
# require './tree_map'
# require 'date'
# require 'pp'

# pom_sheet_path = "/home/salmonax/Dropbox/2014 Pomodoro.txt"
# poms_input = File.open(pom_sheet_path,"r")
# pom_parser = PomParser.new(poms_input)

# csv_writer = CSVwriter.new(pom_parser)


# # csv_for_spreadsheet = "/home/salmonax/@work/naomi/for_spreadsheet.csv"
# # spreadsheet_output = File.open(csv_for_spreadsheet,"w")

# # csv_writer.write_for_days(spreadsheet_output)

# csv_output = "/home/salmonax/@work/naomi/output.csv"
# output_file = File.open(csv_output,"w")
# csv_writer.write(output_file)