class CSVwriter
  def initialize(parser,output=nil)
    @parser = parser
    @header = "Date,Start Time,End Time,Tags,Category,Task,Poms"
  end

  def write(output)
      @output = output
      @output.puts(@header)
      @parser.tasks.each { |task| write_line(task) }
  end

  private

  def write_line(task)
    @output.puts "#{task.date},#{task.start_time},"\
                  "#{task.end_time},#{task.tags.join},#{task.category},"\
                  "\"#{task.task}\",#{task.poms},\r\n"
  end

end