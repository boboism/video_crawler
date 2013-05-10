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

ENV['http_proxy'] = 'https://172.18.199.158:8087'

ARCHIVE_PATTERN = "http://www.torrentkitty.com/archive/%{date}/%{page}"
(DateTime.new(2011,11,8)..DateTime.now).map{|date| date.strftime("%Y-%m-%-d")}.each do |date|
  begin
    doc = Nokogiri::HTML(open(ARCHIVE_PATTERN % {date: date, page: 1}))
  rescue
  end
  next unless doc
  max_page = doc.css(".pagination a").select{ |link| /\d+/ =~ link.content }.map{ |link| link.content.to_i }.max || 1
  
  (1..max_page).each do |page|
    begin 
      doc = Nokogiri::HTML(open(ARCHIVE_PATTERN % {date: date, page: page})) 
    rescue
    end
    next unless doc
    doc.css("table tr:not(:first) .action a[rel='information']").map{|link| DOMAIN_PATTERN % {info: link['href']}}.each do |url|
      p url
      begin
        doc          = Nokogiri::HTML(open(url))
      rescue
        next
      end
      title        = doc.css(".wrapper h2").first ? doc.css(".wrapper h2").first.content.gsub("Details for torrent:", "").strip : ""
      torrent_hash = doc.css("table.detailSummary tr:nth-child(2) td:first").first ? doc.css("table.detailSummary tr:nth-child(2) td:first").first.content : ""
      num_of_files = doc.css("table.detailSummary tr:nth-child(3) td:first").first ? doc.css("table.detailSummary tr:nth-child(3) td:first").first.content : ""
      content_size = doc.css("table.detailSummary tr:nth-child(4) td:first").first ? doc.css("table.detailSummary tr:nth-child(4) td:first").first.content : ""
      created_at   = doc.css("table.detailSummary tr:nth-child(5) td:first").first ? doc.css("table.detailSummary tr:nth-child(5) td:first").first.content : ""
      keywords     = doc.css("table.detailSummary tr:nth-child(6) td:first a").select{|link| /\w+/ =~ link[:title]}.map{|link| link[:title]}
      magnet       = doc.css("textarea.magnet-link").first ? doc.css("textarea.magnet-link").first.content : ""
      md5          = Digest::MD5.hexdigest(url)
      movie        = { title:        title,
                       torrent_hash: torrent_hash,
                       num_of_files: num_of_files,
                       content_size: content_size,
                       created_at:   created_at,
                       keywords:     keywords,
                       magnet:       magnet,
                       md5:          md5 }
      unless movies.find(md5: movie[:md5]).first
        p "inserting #{movie.inspect}"
        movies.insert movie
      end
    end
  end
  
end

