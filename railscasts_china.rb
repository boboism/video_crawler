require 'anemone'
require 'digest/md5'
require 'mongo'
require 'date_core'
require 'open-uri'

ARCHIVE_PATTERN = "http://railscasts-china.com/?page=%{page}"
urls = []
(1..4).map{|page| ARCHIVE_PATTERN % {page: page}}.each do |url|
  begin 
    doc = Nokogiri::HTML(open(url))
  rescue
  end
  doc.css("a").each do |link|
    urls << link['href'].gsub("?autoplay=true","") if link['href'] =~ %r[autoplay=true$]i
  end
end
medias = []
urls.map{|url| "http://railscasts-china.com%{page}" % {page: url}}.each do |url|
  begin 
    doc = Nokogiri::HTML(open(url))
  rescue
  end
  doc.css("a").each do |link|
    medias << link['href'] if link['href'] =~ %r[mp4$]i  
  end
end

File.open('railscasts-china_links.txt', 'w') do |f|
  medias.each do |url|
    f.puts "#{url}\n"
  end
end
