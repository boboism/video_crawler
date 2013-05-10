require 'anemone'
require 'digest/md5'
require 'mongo'

# Patterns
ENTRY_PATTERN = "http://www.oabt.org/?cid=5"
PAGE_PATTERN  = %r[cid=(?:5|25|6|7|8|11)(?:&page=\d+)?$]
ANY_PATTERN   = PAGE_PATTERN

db = Mongo::Connection.new.db("oabt_org")
movies = db["movie"]

options = {
  :threads              => 1,
  :verbose              => true,
  :discard_page_bodies  => true,
  :user_agent           => "Mozilla...",
  :delay                => 0,
  :obey_robots_txt      => true,
  :depth_limit          => 1,
  :redirect_limit       => 5,
  :storage              => nil,
  :cookies              => nil,
  :accept_cookies       => true,
  :skip_query_strings   => false,
  :proxy_host           => nil,
  :proxy_port           => false,
  :read_timeout         => 20
}
p "begin"
Anemone.crawl(ENTRY_PATTERN, options) do |anemone|

  anemone.focus_crawl do |page|
    p "focus #{page.url}"
    page.links.keep_if{|link| link.to_s =~ ANY_PATTERN}
  end

  anemone.on_pages_like(PAGE_PATTERN) do |page|
    if page.doc
      p "crawl #{page.url}"
      p "crawl header:#{page.headers}"
      p "crawl code:#{page.code}"
      p "crawl body:#{page.body}"
      p "crawl links:#{(page.links||[]).collect(&:to_s).join('\n')}"
      page.doc.css('tr').each do |tr|
        p "crawl tr"
        title, id, ref_url = tr.css('td.name.magTitle a').collect{|a| [a.text, a['rel'], a['href']]}.first
        if id && (md5 = Digest::MD5.hexdigest(id)) && (movies.find({"md5" => md5}).first.nil?)
          cat = tr.css("a.sbule").collect{|a| [a['href'][/\d+/], a.text]}.first.join('|')
          ed2k_url, mag_url, thunder_url = (tr.css('td.dow a.ed2kDown').first||{})['ed2k'], (tr.css('td.dow a.magDown').first||{})['href'], (tr.css('td.dow a.thunder').first||{})['thunderhref']
          movie = {:md5 => md5, :cat => cat, :ref_url => ref_url, :title => title, :ed2k_url => ed2k_url, :mag_url => mag_url, :thunder_url => thunder_url}
          p "Inserting #{movie.inspect}"
          movies.insert movie
        end
      end
    end
  end

end
