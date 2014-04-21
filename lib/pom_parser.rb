class PomParser
  attr_reader :tasks, :days, :full, :total, :jots, :tag_labels, :targets

  def initialize(f)
    @file = f
    @tasks = []
    @days = {}
    @full = { tags: {}, categories: {}, books: {}, sum: 0 }
    @total = 0 
    @jots = {}
    @tag_labels = {}
    @mid_intervals = %w|January February March April May June July August September October November December|
    @big_intervals = %w| Beginning Middle End |
    @targets = init_targets_hash
  
    build_tasks
  end

  private

  def build_tasks
    line_array = []
    @file.each { |line| line_array << line.gsub(%r{\r|\n},'')  }

    line_array = line_array-["\r\n"]

    current_date = ""
    line_array.each_with_index do |line, i|
      next if skippable?(line)
      break if breakable?(line)
      if is_date?(line) #set date on each date line
        current_date = line
        @days.merge!({ current_date => { poms: 0, tags: {}, categories: {} } })
      elsif jottable?(line)  
        jot_down(line)
      elsif tag_label?(line)
        define_tag_label(line)
      elsif monthly_target?(line)
        define_monthly_target(line)
      elsif task?(line)
        task = Task.new(current_date,line)
        @tasks << task
        sum_categories_and_tags(task)
        book = extract_book(task)
        if book    
          @full[:books].merge!(book) { |k,v1,v2| v1+v2 }
        end
      end
    end
    @full[:sum] = @full[:tags][:sum] + @full[:categories][:sum]
  end

  def task?(line)
    first = line.split(' ').first
    #returns nil if regex fails, false if number is too big.
    #still fails when random number on own line
    first =~ /^\d{1,2}($|.5)/ && first.to_f <= 30
  end

  def monthly_target?(line)
    (@big_intervals+@mid_intervals).include? line.split(' ').first
  end


  def define_monthly_target(line)
    time_period = line.split(' ').first
    target = line.split(' ').last.to_i

    if @big_intervals.include?(time_period)
      @targets[:arcs][time_period] = target
      define_monthlies_from_arc(time_period)
    elsif @mid_intervals.include?(time_period)
      @targets[:months][time_period] = target
    end
    # p @targets
  end

  private 

  def define_monthlies_from_arc(arc)
    i = @big_intervals.index(arc)
    @mid_intervals[0+i*4..3+i*4].each do |month|
      @targets[:months][month] = @targets[:arcs][arc]
    end
  end

  # -- Might need this for something else --
  # def init_targets_hash 
  #   targets = {}
  #   @big_intervals.each_with_index do |big_interval, i|
  #     hash_per_third = {}
  #     @mid_intervals[(i+1)*3-1..(i+1)*3+2].each do |month|
  #       hash_per_third.merge!({month => 0})
  #     end
  #     targets.merge!({ big_interval => hash_per_third })
  #   end
  #   targets
  # end

  def init_targets_hash 
    targets = { arcs: {}, months: {} }
    @big_intervals.each do |big_interval|
      targets[:arcs][big_interval] = 0
    end
    @mid_intervals.each do |mid_interval|
      targets[:months][mid_interval] = 0
    end
    targets
  end

  def sum_categories_and_tags(task)
    #start building the hash of daily values
    current_date = task.properties[:date]
    task_poms = task.properties[:poms]
    tag_totals_hash = @days[current_date][:tags]
    category_totals_hash = @days[current_date][:categories]
    @days[current_date][:poms] += task_poms #tally all task poms
    task.properties[:tags].each do |tag|
      # tag_branch_label = get_label(tag[0])
      # tag_leaf_label = get_modality(tag)
      tag_branch_label = tag[0]
      tag_leaf_label = tag

      add_to_key(tag_totals_hash,tag,task_poms)

      @full[:tags][tag_branch_label] = {} if @full[:tags][tag_branch_label].nil? #for nesting
      add_to_key(@full[:tags][tag_branch_label],tag_leaf_label,task_poms)

      @full[:tags][tag_branch_label][:sum] = 0 if @full[:tags][tag_branch_label][:sum].nil?
      @full[:tags][tag_branch_label][:sum] += task_poms

      @full[:tags][:sum] = 0 if @full[:tags][:sum].nil?
      @full[:tags][:sum] += task_poms
    end

    add_to_key(category_totals_hash,task.properties[:category],task_poms) #-> maybe add support for multiple, later
    add_to_key(@full[:categories],task.properties[:category],task_poms)

    @full[:categories][:sum] = 0 if @full[:categories][:sum].nil?
    @full[:categories][:sum] += task_poms

    @total += task_poms
  end

  def grab_book_title(name)
    prepositions = %w{in and at on by}
    book_title = []
    name.split(',').last.split(' ').reverse.each do |word|
      if word.capitalize == word or word.upcase == word or prepositions.include?(word)
        book_title << word
      else
        break
        # return book_title.reverse.join(' ')
      end
    end
    if prepositions.include?(book_title.last) or
      book_title.last =~ /[rR]ead/
      book_title.pop
    end
    book_title.reverse.join(' ')
  end

  def extract_book(task)
    prepositions = %w{with a in and at on by}
    starter = /\b([Ss]tart|[Bb]egin|[Cc]ontinue|[kKeep]) [Rr]eading\b/
    read = /\b[rR]ead(\smore)?\b/
    just_reading_around = /\b[rR]ead\s(about|at|a|over)\b/
    arrow = /->/

    current_date = task.properties[:date]
    task_poms = task.properties[:poms]
    task_name = task.properties[:task]
    task_category = task.properties[:category]
    if task_name =~ arrow #easiest case
      book, progress = task_name.split(/\s*->\s*/)
      book = grab_book_title(book)
    elsif task_category =~ starter#also easy
      book = task_name
    elsif task_name =~ starter #still pretty easy
      book = task_name.rpartition(starter).last.strip
      book = nil unless book[0].upcase == book[0]
    #now for the hard case...
    elsif task_name =~ read
      unless task_name =~ just_reading_around
        book = task_name.rpartition(read).last.strip
        # book = nil unless book[0].upcase == book[0]
        no_lowers = true
        book.split(' ').each do |word|
          if word[0] =~ /[a-z]/ and !prepositions.include?(word)
            # p book
            # p "#{word[0].downcase} and #{word[0]}"
            no_lowers = false 
            break
          end
        end
        unless no_lowers
          book = nil
        else
          @full[:books][:sum] = 0 if @full[:books][:sum].nil?
          @full[:books][:sum] += task_poms
        end
      end
    end
    #remember: case to search categories for book titles that already exist!
    hash = { book => task_poms } if book
  end

  def get_label(tag)
    label = @tag_labels[tag]
    return label.nil? ? tag : label
  end

  def get_modality(tag) #will be settable fromsheet
    tag.length == 1 ? "Reading" : "Practice"
  end

  def tag_label?(line)
    command = line.split(" ")[0]
    command.size == 1 and command !~ /[0-9]/
  end

  def define_tag_label(line)
    target_hash = @tag_labels
    target_key = line.split(' ')[0]
    value = line.split(' ')[1..-1].join(' ')
    add_to_key(target_hash, target_key, value)
  end

  def jottable?(line) #quick and dirty check. Parantheses will be optional, like Ruby
    line.split(" ")[1][0] == "(" and line.split(" ")[-1][-1] == ")"
  end

  def jot_down(line) #also quick and dirty; breaks with extra parentheses
    target_hash = @jots
    target_key = line.split("(")[0].gsub(%r{\r|\n|\t|\)|\s},'')
    value = [line.split('(')[1].gsub(%r{\r|\n|\t|\)},'')]
    add_to_key(target_hash, target_key, value)
  end

  def add_to_key(target_hash,target_key,value) #could refactor with *target_hashes
    target_hash.merge!({ target_key => value }) { |k, old_v, new_v| old_v + new_v }
  end

  def skippable?(line)
    #skip empty, dashed lines, and break indicators
    line.split(" ")[0].nil? or
    line =~ %r{^--} or  
    line.split(" ")[0].upcase == "BREAK"
    #in future: break lines will take the previous end-time as start time and end 30 minutes later
  end

  def breakable?(line)
    #break on //--
    line[0..3] == "//--"
  end

  def is_date?(line)
    line =~ %r|.*/.*/.*|
  end

end