#!/usr/bin/env ruby

# Set your location via these environment variables, or, simply change it here.

latitude  = ENV["LATITUDE"]  || 39.768
longitude = ENV["LONGITUDE"] || -86.158
location = latitude, longitude

require "json"
require "net/http"
require "uri"

uri = URI.parse("http://api.open-notify.org/iss-now.json")

http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new(uri.request_uri)

response = http.request(request)

exit 1 unless response.code == "200"

result = JSON.parse(response.body)

iss_location = result["iss_position"]["latitude"], result["iss_position"]["longitude"]

# Lovingly borrowed from https://gist.github.com/j05h/673425
class Numeric
  def radians
    self * Math::PI / 180
  end
end

def haversine_distance(location1, location2)
  lat1, lon1 = location1.map(&:to_f)
  lat2, lon2 = location2.map(&:to_f)
  latitude_difference = (lat2 - lat1).radians
  longitude_difference = (lon2 - lon1).radians

  a = Math.sin(latitude_difference / 2) ** 2 +
    Math.cos(lat1.radians) * Math.cos(lat2.radians) *
    Math.sin(longitude_difference/2) ** 2

  c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  6371 * c
end

distance_in_km = haversine_distance(location, iss_location)
distance_in_mi = distance_in_km * 0.621371

puts "distance_to_iss.miles #{distance_in_mi}"
puts "distance_to_iss.kilometers #{distance_in_km}"
