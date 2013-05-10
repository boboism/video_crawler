require 'anemone'
require 'digest/md5'
require 'mongo'
require 'date_core'
require 'open-uri'

# Patterns
ENTRY_PATTERN = "http://www.torrentkitty.com/archive/"
PAGE_PATTERN  = %r[archive] #%r[information\/\w{48}$]i 
ANY_PATTERN   = %r[archive]# Regexp.union %r[archive]i, PAGE_PATTERN
MEDIA_PATTERN = %r[^(ed2k|magnet|thunder|ftp):\/\/]
DOMAIN_PATTERN = "http://www.torrentkitty.com%{info}"

db = Mongo::Connection.new.db("torrentkitty")
movies = db["movie"]
#movies.remove

ARCHIVE_PATTERN = "http://happycasts.net/episodes/%{page}"
urls = []
(1..56).map{|page| ARCHIVE_PATTERN % {page: page}}.each do |url|
  begin 
    doc = Nokogiri::HTML(open(url))
  rescue
  end
  urls << doc.css("a[href$='mov']").first['href']
end

File.open('happycasts_links.txt', 'w') do |f|
  urls.each do |url|
    f.puts "#{url}\n"
  end
end
