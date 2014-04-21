require 'spreadsheet'



xls_file = 'pom_spread.xls'
book = Spreadsheet.open(xls_file)

# sheet = book.worksheet('Done')
# sheet = book.create_worksheet(name: 'PomParsley')




my_sheet = XLSupdater.new(xls_file,'PomParsley')
my_sheet.update('pom_spread1.xls')