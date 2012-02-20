require 'rubygems'
require 'bundler'
Bundler.require

require 'faye'
require './quizville'

class ServerAuth
  def incoming(message, callback)
    if message['channel'] !~ %r{^/meta/}
      if message['ext']['auth_token'] != 'token'
        message['error'] = 'Invalid authentication token'
      end
    end
    callback.call(message)
  end
end

bayeux = Faye::RackAdapter.new(:mount => '/faye', :timeout => 45)
bayeux.add_extension(ServerAuth.new)

run bayeux
run Sinatra::Application
