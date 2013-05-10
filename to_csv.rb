require 'mongo'
require 'csv'

db = Mongo::Connection.new.db("btmee_com")
movies = db['movie']

CSV.open("download.csv", "wb", encoding: "utf-8") do |csv|
  movies.find.each do |movie|
    csv << movie.to_a.flatten
  end
end
