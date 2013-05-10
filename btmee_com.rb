require 'anemone'
require 'digest/md5'
require 'mongo'

# Patterns
ENTRY_PATTERN = "http://btmee.com/movie/"
PAGE_PATTERN  = %r[(?:movie|720p|romance|action|hr-hdtv|comedy|mp4|mkv|mystery|war|horror|sci-fi|drama|thriller|animation|dvd|rmvb|1080p)\/\d+[\/]?$]
ANY_PATTERN   = PAGE_PATTERN

db     = Mongo::Connection.new.db("btmee_com")
movies = db["movie"]
movies.remove

Anemone.crawl(ENTRY_PATTERN) do |anemone|

  anemone.focus_crawl do |page|
    page.links.keep_if{|link| link.to_s =~ ANY_PATTERN}
  end

  anemone.on_pages_like(PAGE_PATTERN) do |page|
    if page.doc
      page.doc.css('tr').each do |tr|
        title, id, ref_url  = tr.css('td.name.magTitle a').collect{|a| [a.text, a['href'][/\d+/], a['href']]}.first
        if id && (md5 = Digest::MD5.hexdigest(id)) && (movies.find({"md5" => md5}).first.nil?)
          cat               = tr.css("a.sbule").collect{|a| [a['href'].scan(%r[([a-zA-Z0-9_-]+)[/]?$]).flatten.last, a.text]}.first.join('|')
          ed2k_url, mag_url = (tr.css('td.dow a.ed2kDown').first||{})['ed2k'], (tr.css('td.dow a.magDown').first||{})['href']
          movie             = {:md5 => md5, :cat => cat, :ref_url => ref_url, :title => title, :ed2k_url => ed2k_url, :mag_url => mag_url}
          p "Inserting #{movie.inspect}"
          movies.insert movie
        end
      end
    end
  end

end
