# add json tweet info to the database

# limit annoying text output in irb
conf.return_format = "=> limited output\n %.2048s\n"

require 'json'
require 'pp'
# ^ a command to 'pretty print' json objects so they're
# easy to read
# Ex: pp tweets[0]
require 'active_record'
# also need 'mysql' gem installed for this to work

# lets the user type the file name
puts "Enter the name of a JSON file"
file = gets
json = IO.readlines(file)

# testing this out on the sample data from Dropbox
# json = IO.readlines('data.txt')

# A function to test if the tweet text matches Terri's specs.
def matches_specs(text)
  text = text.downcase
  matches = false

  # some of Terri's terms were redundant so I removed them
  matches = true if text =~ /\bsid|pakistan[.]* rendition|apartheid|apart[.]* regime|apart[.]* state|palestin[.]*/
  matches = true if text =~ /israel/ and text =~ /human rights violations/

  matches
end

# turn each line of JSON into a Ruby object and add it to the array
tweets = Array.new
json.each_with_index do |line, i|
  begin
    tweets.push JSON.parse(line)
  rescue
    # if it doesn't work print out the index of the offending line
    puts i
    # not sure where that gobbledygook on line 44959 came from
  end
end 

# get the tweets that match the search criterion to a new array
relevant_tweets = Array.new
tweets.each do |tweet|
  relevant = false
  
  # if there's a link in the tweet, see if it goes to WeThePeople
  if tweet.keys.include? "entities"
    if tweet["entities"].keys.include? "urls"
      tweet["entities"]["urls"].each do |url|
        if url["expanded_url"] =~ /petitions\.whitehouse\.gov/
          relevant = true
        end
      end
    end
  end

  # check for the phrases
  relevant = true if matches_specs tweet["text"]

  relevant_tweets.push tweet if relevant
end


# a lot of WtP links!
# relevant_tweets.each { |t| puts t["entities"]["urls"][0]["expanded_url"]}
# relevant_tweets.each { |t| puts t["text"]}

# mysql table setup
# only need to add 'places' table if we're doing that

#create table statuses (id CHAR(18) NOT NULL PRIMARY KEY, created_at DATETIME, text VARCHAR(180), longitude FLOAT, latitude FLOAT, favorite_count INT, retweet_count INT, user_id VARCHAR(18), user_followers_count INT, user_friends_count INT, user_location VARCHAR(30), user_screen_name VARCHAR(15));

#create table urls (id INT NOT NULL PRIMARY KEY AUTO_INCREMENT, status_id CHAR(18) NOT NULL, url VARCHAR(1024), FOREIGN KEY (status_id) References statuses(id));

# add to the database with Active Record
ActiveRecord::Base.establish_connection(:adapter => "mysql",
                                        :host => "localhost",
                                        :database => "test",
                                        :password => "root")
#ActiveRecord::Base.connection.close


# create classes with ActiveRecord that connect to the database tables
class Status < ActiveRecord::Base
  has_many :urls
end

class Url < ActiveRecord::Base
  belongs_to :status
end


# clear the tables if needed
records = Url.all
records.each do |r|
  r.delete
end

records = Status.all
records.each do |r|
  r.delete
end


# add the relevant tweets to the database
#t = relevant_tweets[168]
relevant_tweets.each_with_index do |t, i|
  created_at = DateTime.strptime(t['created_at'], '%a %b %d %H:%M:%S %z %Y')
  location = t['user']['location'].gsub(/[^\p{Latin}\/ \-,]/, '')

  begin
    # if the object contains latitude and longitude
    if t['coordinates'] != nil
      status = Status.create(:id => t['id_str'], :text => t['text'],
                             :created_at => created_at,
                             :longitude => t['coordinates']['coordinates'][0],
                             :latitude => t['coordinates']['coordinates'][1],
                             :favorite_count => t['favorite_count'],
                             :retweet_count => t['retweet_count'],
                             :user_id => t['user']['id_str'],
                             :user_followers_count => t['user']['followers_count'],
                             :user_friends_count => t['user']['friends_count'],
                             :user_location => location,
                             :user_screen_name => t['user']['screen_name'])
    else
      # otherwise no longitude and latitude this time
      status = Status.create(:id => t['id_str'], :text => t['text'],
                             :created_at => created_at,
                             :favorite_count => t['favorite_count'],
                             :retweet_count => t['retweet_count'],
                             :user_id => t['user']['id_str'],
                             :user_followers_count => t['user']['followers_count'],
                             :user_friends_count => t['user']['friends_count'],
                             :user_location => location,
                             :user_screen_name => t['user']['screen_name'])
    end    
  rescue
    # if the new row doesn't get created in the database, print out
    # some helpful info so we can look to see what's going on
    puts i.to_s
    puts t['id_str']
    puts t['text']
    break
  end

  # add URLs, if there are any. I set the urls table to hold 1024
  # characters, so limit the url characters to that many
  if t["entities"].keys.include? "urls"
    t["entities"]["urls"].each do |url|
      status.urls.create(:url => url['expanded_url'][0..1023])
    end
  end
end




# see what's in the database:
# s = Status.all
# u = Url.all

# see how many relevant tweets include latitude and longitude:
# relevant_tweets.each_with_index do |t, i|
#   print i if t['coordinates'] != nil
# end
