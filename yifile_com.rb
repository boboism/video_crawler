require 'anemone'
require 'digest/md5'
require 'mongo'

# Patterns
ENTRY_PATTERN = "http://www.yifile.com/category/1/&page=1"
PAGE_PATTERN  = %r[article\/\d+\.html$]i 
ANY_PATTERN   = Regexp.union %r[category\/\d+\/&page=d+$]i, PAGE_PATTERN
MEDIA_PATTERN = %r[^(ed2k|magnet|thunder|ftp):\/\/]

db = Mongo::Connection.new.db("qtfy30")
movies = db["movie"]
movies.remove

Anemone.crawl(ENTRY_PATTERN) do |anemone|

  anemone.focus_crawl do |page|
    page.links.keep_if{|link| link.to_s =~ ANY_PATTERN}
  end

  anemone.on_pages_like(PAGE_PATTERN) do |page|
    if page.doc && (page.doc.css(".postmetadata a[rel='tag'][href='http://www.qtfy30.cn/tag/%e7%94%b5%e5%bd%b1']").size > 0)
      title = page.doc.css(".post h2").first.content
      ref_url = page.url.to_s
      movie = {:md5 => Digest::MD5.hexdigest(ref_url), :title => title, :ref_url => ref_url}
      down_url = page.doc.css("a").select{|link| link['href'] =~ MEDIA_PATTERN}.each_with_index{|link, index| movie.merge!({"download_url_#{index+1}" => link.content.strip, "down_url_#{index+1}" => link['href']})}
      if movies.find(:md5 => movie[:md5]).first.nil?
        p "Inserting #{movie.inspect}"
        movies.insert movie
      end
    end
  end

end
