# encoding: UTF-8
require 'open-uri'
require 'nokogiri'
require 'digest/md5'
require 'mongo'
db = Mongo::Connection.new.db("somag_net")
movies = db['movie']

(1..2198).each do |i|
  uri = URI.parse("http://www.somag.net/category/%E7%94%B5%E5%BD%B1/#{i}/")
  doc = Nokogiri::HTML(open(uri)) 
  doc.css('li.post') do |li|
    title, ref_url = li.css(".entry h2 a").collect{|a| [a.text, a['href']]}.first
    if (md5 = Digest::MD5.hexdigest(ref_url)) && (movies.find({"md5" => md5}).first.nil?)
      mag_url = (li.css(".meta .info .magnet").first||{})['href'] 
      movie = {:md5 => md5, :ref_url => ref_url, :title => title, :mag_url => mag_url}
      p "Inserting #{movie.inspect}"
      movies.insert movie
    end
  end
end
