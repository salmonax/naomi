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
    @abbreviations = {}
    @category_schema = {}
    build_tasks
  end

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
      elsif category_nester?(line)
        merge_to_category_hash(line,@category_schema)
      elsif tag_label?(line)
        define_tag_label(line)
      elsif monthly_target?(line)
        define_monthly_target(line)
      elsif task?(line)
        task = Task.new(current_date,line)
        @tasks << task
        sum_categories_and_tags(task)
        book = extract_book(task)
        @full[:books].merge!(book) { |k,v1,v2| v1+v2 } if book
      end
    end
    merge_books_acronyms!
    #fuzzy match would go here
    p @category_schema
    p @full[:nested] = nestle_flat_hash(@full[:categories],@category_schema)
    @full[:categories] = divide_in_three(@full[:categories])
    @full[:books] = divide_in_three(@full[:books])
  end

  def divide_in_three(hash)
    sorted_array = hash.sort_by { |key, value| value}.reverse
    total = hash.values.inject(:+)
    top_level_names = ["Primary","Secondary","Tertiary"]
    new_hash = {}
    tally = 0
    triad = sorted_array.size/3
    sorted_array.each_with_index do |item, i| 
      new_hash[top_level_names[[i-1,0].max/triad]] ||= {}
      new_hash[top_level_names[[i-1,0].max/triad]].merge!({item[0] => item[1]})
    end
    new_hash
  end

  def category_nester?(line)
    line =~ /^[a-zA-Z\s].*:/ and line.split(' ')[-1] != '()' # kludgy undone-task check
  end

  def merge_books_acronyms!
    books_hash = @full[:books]
    new_hash = books_hash.clone
    books_hash.each do |key, value|
      title, acronym = key.split(/\s?[\(\)]/)
      if acronym 
        new_hash[title] = new_hash[acronym]+value
        new_hash.delete(key)
        new_hash.delete(acronym)
      end
    end
    @full[:books] = new_hash
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
  def skippable?(line)
    #skip empty, dashed lines, and break indicators
    line.split(" ")[0].nil? or
    line =~ %r{^--} or  
    line.split(" ")[0].upcase == "BREAK"
    #in future: break lines will take the previous end-time as start time and end 30 minutes later
  end
  def tag_label?(line)
    command = line.split(" ")[0]
    command.size == 1 and command !~ /[0-9]/
  end

  def jottable?(line) #quick and dirty check. Parantheses will be optional, like Ruby
    line.split(" ")[1][0] == "(" and line.split(" ")[-1][-1] == ")"
  end

  def breakable?(line)
    #break on //--
    line[0..3] == "//--"
  end

  def is_date?(line)
    line =~ %r|.*/.*/.*|
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
  end

  def define_monthlies_from_arc(arc)
    i = @big_intervals.index(arc)
    @mid_intervals[0+i*4..3+i*4].each do |month|
      @targets[:months][month] = @targets[:arcs][arc]
    end
  end

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
    end

    add_to_key(category_totals_hash,task.properties[:category],task_poms) #-> maybe add support for multiple, later
    add_to_key(@full[:categories],task.properties[:category],task_poms)

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
      end
    end
    if prepositions.include?(book_title.last) or book_title.last =~ /[rR]ead/
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
        no_lowers = true
        book.split(' ').each do |word|
          if word[0] =~ /[a-z]/ and !prepositions.include?(word)
            no_lowers = false 
            break
          end
        end
        book = nil unless no_lowers
      end
    end
    #REMEMBER: case to search categories for book titles that already exist!
    hash = { book => task_poms }  if book
  end

  def get_label(tag)
    label = @tag_labels[tag]
    return label.nil? ? tag : label
  end

  def get_modality(tag) #will be settable from pomsheet
    tag.length == 1 ? "Reading" : "Practice"
  end

  def define_tag_label(line)
    target_hash = @tag_labels
    target_key = line.split(' ')[0]
    value = line.split(' ')[1..-1].join(' ')
    add_to_key(target_hash, target_key, value)
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

## BEGIN array nestling module
## USAGE:
##     #nestle_array(category_definitions,to_be_nested) spits out a nested hash. 
##     #merge_to_category_hash for single lines
##     #nestle_flat_hash will map a flat hash onto a nested hash of a given key structure, adding numerical values

  def nestle_array(array,nested)
    array.each do |line|
      merge_to_category_hash(line,nested)
    end
    nested
  end

  def merge_to_category_hash(line,nested)
    categories = line.split(/\s?:\s?/)
    to_merge = {}
    puts "#{line}"
    categories.each_with_index do |category, i|

      target_key = categories[i]
      new_value = categories[i+1] ? categories[i+1] : 0

      deep_merge_add(nested, target_key, new_value)
    end
  end

  def deep_merge_add(nested,target_k,new_v,top=true) #this is used build a nested hash from scratch, using an array
    if target_k == "PomParsley" 
      puts "#{target_k} => #{new_v} MERGES INTO #{nested}"
    end

    if target_k == "PomParsley" and nested == {"Blender Class"=>0, "Corgi"=>0}
      puts "YOU FOUND ME! I'm about to do a very bad THING!"
   # only merge if it's at the top level!!!
    end
    new_v = {new_v => 0} if new_v.class == String
    if hash_has_key?(nested,target_k)
      puts "I have the key!"
      if nested.keys.include?(target_k)
        if nested[target_k].class == Hash
          nested[target_k].merge!(new_v)
        else
          nested[target_k] = new_v
        end
      else
        nested.each do |k,v|
          deep_merge_add(v,target_k,new_v,false) if v.class == Hash
        end
      end
    else

        if top 
          puts "I don't have the key and IMA MERGE ANYWAY!"
          nested.merge!({target_k => new_v}) 
        end
    end
    # if target_k == "PomParsley" 
    #   puts "!! #{target_k} => #{new_v} NOW IN #{nested}"
    # end
  end

  def hash_has_key?(hash,key)
    if hash.keys.include?(key)
      return true
    else
      hash.each do |k,v|
        return hash_has_key?(v,key) if v.class == Hash
      end
    end
    false
  end

  def nestle_flat_hash(flat,nested)
    flat.each { |k,v| merge_at_key(nested,k,v) }
    return nested
  end

  def merge_at_key(nested,target_k,new_v) #this is for restructuring a flat hash to nested
    if hash_has_key?(nested,target_k)
      if nested.keys.include?(target_k) 
        if nested[target_k].class != Hash 
          nested.merge!({target_k => new_v}) { |k,v1,v2| v1+v2 }
        else #if v is hash, it means the key has children, so add a "Misc" category for top-level category activity

          # NOTE: commented code erroneously subtracts value

          # extant_values = nested[target_k].values.inject(:+)
          # nested[target_k].merge!({"Misc" => new_v-extant_values}) { |k,v1,v2| v1+v2 }
          
          nested[target_k].merge!({"Misc" => new_v}) { |k,v1,v2| v1+v2 }
          
          
        end
      else
        nested.each do |k,v|
          merge_at_key(v,target_k,new_v) if v.class == Hash
        end
      end
    else
      nested.merge!({target_k => new_v})
    end
  end

end