# frozen_string_literal: true

require 'net/http'
require 'sinatra'
require 'sinatra/cors'

set :allow_origin, '*'
set :allow_methods, 'GET,HEAD,POST'
set :allow_headers, 'content-type,if-modified-since'
set :expose_headers, 'location,link'

get '/' do
  'ok'
end

#  GET /a?u=<URI encoded value of window.location.href>
# e.g. /a?u=http%3A%2F%2Fglitch.me%2Fl33t
get '/a' do
  handle_uri(params['u'])
end

# POST /b { u: <value of window.location.href> }
# e.g. /b { u: "http://glitch.me/l33t" }
post '/b' do
  body = request.body.read
  data = JSON.parse(body)
  handle_uri(data['u'])
end

# parse the hostname out of the received uri and warn if invalid
def handle_uri(uri)
  puts "Received: #{uri}"
  parsed = URI(uri)

  unless valid?(parsed.host)
    error_message = "Received request from invalid domain: #{uri}"
    puts error_message
    post_to_slack! error_message
  end
end

# development, staging and prod are ok; everything else not so much
def valid?(host)
  return true if host =~ /\.artsy.net$/

  # TODO: uncomment after this is verified working
  # return true if host == 'localhost'
  # return true if host == '127.0.0.1'

  false
end

def post_to_slack!(message)
  slack_endpoint = URI(ENV['SLACK_ENDPOINT'])
  payload = {
    username: 'Francis Beacon',
    text: message
  }
  Net::HTTP.post slack_endpoint, payload.to_json, 'Content-Type' => 'application/json'
end
