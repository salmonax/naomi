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

  def write_file(file)
    file.puts JSON.generate(@totals)
  end

  def write
    JSON.generate(@totals)
  end

  def write_area_chart
    points = []
    # all_tags = @parser.full[:tags].keys+["None"]
    all_tags = ["!","None","R","RR"]
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

  def zero_nil(hash)
    hash.nil? ? 0 : hash
  end
end