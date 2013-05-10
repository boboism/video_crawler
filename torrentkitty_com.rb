require 'anemone'
require 'digest/md5'
require 'mongo'
require 'date_core'
require 'open-uri'

# Patterns
PAGE_PATTERN  = %r[information]i 
ANY_PATTERN   = Regexp.union %r[\d+], PAGE_PATTERN
ARCHIVE_PATTERN = "http://www.torrentkitty.com/archive/%{date}/%{page}"

db = Mongo::Connection.new.db("torrentkitty")
movies = db["movie"]
movies.remove

# get archive pages
page_urls = (DateTime.new(2007,1,1)..DateTime.now).map{|date| ARCHIVE_PATTERN % {date: date.strftime("%Y-%m-%-d"), page: 1}}.flatten
#(DateTime.new(2007,1,1)..DateTime.now).map{|date| date.strftime("%Y-%m-%-d")}.each do |date|
#  doc = Nokogiri::HTML(open(ARCHIVE_PATTERN % {date: date, page: 1}))
#  max_page = doc.css(".pagination a").select{ |link| /\d+/ =~ link.content }.map{ |link| link.content.to_i }.max || 1
#  current_page_urls = (1..max_page).map{|page| ARCHIVE_PATTERN % {date: date, page: page}}  
#  page_urls << current_page_urls 
#  p current_page_urls
#end

options = {
  :verbose => true,
  :accept_cookies => true,
  :rad_timeout => 20,
  :retry_limit => 0,
  :discard_page_bodies => true,
}

# user anemone to crawl
Anemone.crawl(page_urls, options) do |anemone|

  anemone.focus_crawl do |page|
    page.links.keep_if{|link| link.to_s =~ %r[\d+]}
  end

  anemone.on_pages_like(PAGE_PATTERN) do |page|
    p page.url
    if page.doc
      doc = page.doc
      title        = doc.css(".wrapper h2").first ? doc.css(".wrapper h2").first.content.gsub("Details for torrent:", "").strip : ""
      torrent_hash = doc.css("table.detailSummary tr:nth-child(2) td:first").first ? doc.css("table.detailSummary tr:nth-child(2) td:first").first.content : ""
      num_of_files = doc.css("table.detailSummary tr:nth-child(3) td:first").first ? doc.css("table.detailSummary tr:nth-child(3) td:first").first.content : ""
      content_size = doc.css("table.detailSummary tr:nth-child(4) td:first").first ? doc.css("table.detailSummary tr:nth-child(4) td:first").first.content : ""
      created_at   = doc.css("table.detailSummary tr:nth-child(5) td:first").first ? doc.css("table.detailSummary tr:nth-child(5) td:first").first.content : ""
      keywords     = doc.css("table.detailSummary tr:nth-child(6) td:first a").select{|link| /\w+/ =~ link[:title]}.map{|link| link[:title]}
      magnet       = doc.css("textarea.magnet-link").first ? doc.css("textarea.magnet-link").first.content : ""
      md5          = Digest::MD5.hexdigest(page.url.to_s)
      movie        = { title:        title,
                       torrent_hash: torrent_hash,
                       num_of_files: num_of_files,
                       content_size: content_size,
                       created_at:   created_at,
                       keywords:     keywords,
                       magnet:       magnet,
                       md5:          md5 }
      p "inserting #{movie.inspect}"
      movies.insert movie

    end
  end

end
