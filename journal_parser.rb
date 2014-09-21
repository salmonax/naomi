require 'yomu'

journal_loc = "/home/salmonax/Dropbox/Journal 2013.doc"
journal = Yomu.new(journal_loc)

months = "January|February|March|April|May|June|July|August|September|October|November|December"

weekdays = "Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday"

p journal.text.scan(/#{months}\s\d*\,.*\n/).each { |line| p line }

