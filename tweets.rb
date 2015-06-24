# add json tweet info to the database

# limit annoying stuff in irb
conf.return_format = "=> limited output\n %.5012s\n"

require 'json'

json = IO.readlines('data.txt')


obj = JSON.parse(json[1])

