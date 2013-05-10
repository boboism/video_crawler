require 'anemone'
require 'digest/md5'
require 'mongo'
require 'date_core'
require 'open-uri'

ARCHIVE_PATTERN = "http://vimcasts.org/episodes/archive"
urls = []
begin 
  doc = Nokogiri::HTML(open(ARCHIVE_PATTERN))
rescue
end
doc.css("a.archive").each do |link|
  urls << "http://vimcasts.org#{link['href']}"
  p link['href']
end
medias = []
urls.each do |url|
  begin 
    doc = Nokogiri::HTML(open(url))
  rescue
    next
  end
  medias << doc.css("video source").first['src']
end

File.open('vimcasts.txt', 'w') do |f|
  medias.each do |url|
    f.puts "#{url}\n"
  end
end
