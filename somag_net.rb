# encoding: UTF-8
require 'anemone'
require 'digest/md5'
require 'mongo'
require 'open-uri'

options = {
  :verbose => true,
  :accept_cookies => true,
  :rad_timeout => 20,
  :retry_limit => 0,
  :discard_page_bodies => true,
}

# Patterns
ENTRY_PATTERN = "http://www.somag.net/tag/电影/1/"
PAGE_PATTERN  = %r[tag\/(?:\u7535\u5f71|%E7%94%B5%E5%BD%B1)\/\d+\/$]i
ANY_PATTERN   = PAGE_PATTERN

db = Mongo::Connection.new.db("somag_net")
movies = db["movie"]

Anemone.crawl(URI.parse(URI.escape(ENTRY_PATTERN)), options) do |anemone|

  anemone.focus_crawl do |page|
    page.links.keep_if{|link| link.to_s =~ ANY_PATTERN}
  end

  anemone.on_pages_like(PAGE_PATTERN) do |page|
    if page.doc
      page.doc.css('li.post') do |li|
        title, ref_url = li.css(".entry h2 a").collect{|a| [a.text, a['href']]}.first
        if (md5 = Digest::MD5.hexdigest(ref_url)) && (movies.find({"md5" => md5}).first.nil?)
          mag_url = (li.css(".entry .meta .info .magnet").first||{})['href']
          movie = {:md5 => md5, :ref_url => ref_url, :title => title, :mag_url => mag_url}
          p "Inserting #{movie.inspect}"
          movies.insert movie
        end
      end
    end
  end

end
