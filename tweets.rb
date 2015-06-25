# add json tweet info to the database

# limit annoying text output in irb
conf.return_format = "=> limited output\n %.2048s\n"

require 'json'

# testing this out on the sample data from Dropbox
json = IO.readlines('data.txt')

# A function to test if the tweet text matches Tere's specs.
def matches_specs(text)
  text = text.downcase
  matches = false

  # some of Tere's terms were redundant so I removed them
  matches = true if text =~ /\bsid|pakistan[.]* rendition|apartheid|apart[.]* regime|apart[.]* state|palestin[.]*/
  matches = true if text =~ /israel/ and text =~ /human rights violations/

  matches
end


tweets = Array.new
json.each_with_index do |line, i|
  begin
    tweets.push JSON.parse(line)
  rescue
    # not sure where this gobbledygook came from, line 44959
    puts i
  end
end
  

# get the tweets that match the search criterion
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
relevant_tweets.each { |t| puts t["entities"]["urls"][0]["expanded_url"]}
relevant_tweets.each { |t| puts t["text"]}



# just need to add this to the database now -- a table for tweets, a
# table for the urls [and a table for the entities?]
