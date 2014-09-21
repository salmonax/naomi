class D3writer
  def initialize(parser)
    @parser = parser
    @totals = {}
    build_totals
  end

  def build_totals
    #no check for different input formats yet
    @parser.tasks.each do |task|
      task_time = task.utc.to_i.to_s
      @totals[task_time] = task.poms
    end
  end

  def squeeze_totals # hacked together to try to get only 3 time outputs per day, but CalHeatmap won't
    new_totals = []
    totals_array = @totals.to_a
    eight_hour_sum = 0
    @totals.each_with_index do |item, i|
      eight_hour_sum += item[1]
      if i%8 == 7
        new_totals << item[0] << eight_hour_sum
        eight_hour_sum = 0
      end
    end
    Hash[*new_totals]
  end

  def write_file(file)
    file.puts JSON.generate(@totals)
  end

  def write
    JSON.generate(@totals)
  end

  def write_highstock(section='poms')
      points = []
      @parser.days.each do |date,value|
        date_array = date.split('/')
        date_array = [date_array[2].to_i,date_array[0].to_i,date_array[1].to_i]
        utc_date = Time.new(*date_array).utc.to_i

        value_calculation = -((value[:poms]-value[:output]-value[:output]).to_f)

        point_value = value_calculation

        # point_value = value[section.to_sym]
        

        points << [utc_date*1000,point_value]

      end
      JSON.generate(points.reverse)
  end

  def write_area_chart
    points = []
    # all_tags = @parser.full[:tags].keys+["None"]
    # all_tags = ["!","None","R","RR"]
    all_tags = ["R","RR", "W","WW"]
    @parser.days.each do |k,v|
      point_hash = { "date" => k }
      all_tags.each do |tag|
        point_hash.merge!( { tag => zero_nil(v[:tags][tag]) } )
      end
      points.unshift(point_hash)
      points
    end
    JSON.generate(points)
  end

  def write_area_chart2
    points = []
    # all_tags = @parser.full[:tags].keys+["None"]
    all_tags = ["!","None","R","RR"]
    # pp @parser.days
    @parser.days.each do |k,v|
      point_hash = { "date" => k, "Pom Total" => v[:poms] }
      points.unshift(point_hash)
      points
    end
    JSON.generate(points)
    # pp points
  end

  def zero_nil(hash)
    hash.nil? ? 0 : hash
  end
end

# require "./modules/hash_magic"
# require "./pom_parser"
# require "./task"
# require "json"
# require 'pp'

# pom_sheet_path = "/home/salmonax/Dropbox/2014 Pomodoro.txt"
# poms_input = File.open(pom_sheet_path,"r")
# pom_parser = PomParser.new(poms_input)

# d3 = D3writer.new(pom_parser)
# d3.write_area_chart2