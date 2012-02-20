require 'digest'
require 'sinatra'
require 'haml'
require 'curb'
require 'eventmachine'
require 'json'
require 'cgi'

helpers do
  def faye_path
    "#{request.scheme}://#{request.host}:9001/faye"
  end

  def faye_js_path
    faye_path + ".js"
  end

  def room_url(room)
    "#{request.scheme}://#{request.host}:#{request.port}/r/#{room}"
  end
end

def generate_room
  Digest::MD5.hexdigest(Time.now.to_f.to_s).slice(0, 8)
end

get '/' do  
  haml :index
end

get "/user/:user" do |user|
  # get auth token
  c = Curl::Easy.http_post('https://login.salesforce.com/services/oauth2/token',
    'grant_type=password&client_id=3MVG9rFJvQRVOvk4cxTJa7DLkKTD8NuAg5AexmhUWE.Yv.W4.WgDugtPKYczI602iJPhbd6PI0w91GlaOSl_l&client_secret=4614924466188346354&username=soe%40soe.im.streamingapi&password=FORCE2012!!fYPTI4g84jByOYA6fTE924HuG'
  )
  
  auth_response = JSON.parse(c.body_str)
  
  query = "select Id, Name, Quiz_Date__c, Number_Correct__c, Total_Time__c, Member__r.Name from Quick_Quiz__c where Quiz_Date__c = 2012-02-20 and Member__r.Name = \'#{user}\'"
  
  # get Quick_Quiz__c
  c = Curl::Easy.http_get("#{auth_response['instance_url']}/services/data/v20.0/query?q=#{CGI::escape(query)}"
  ) do |curl|
    curl.headers['Authorization'] = "OAuth #{auth_response['access_token']}"
  end
        
  quiz_response = JSON.parse(c.body_str)
  
  @record = quiz_response['records'][0]
  @id = quiz_response['records'][0]['Id'] 
  
  # after this we need to subscribe
  haml :test
end

get '/subscribe/:user' do |user|  
  client = Faye::Client.new('https://na14.salesforce.com/cometd')


        
  class ForceAuth
    def outgoing(message, callback)
      # Again, leave non-subscribe messages alone
      #unless message['channel'] == '/meta/subscribe'
        #return callback.call(message)
      #end

      # Add ext field if it's not present
      message['ext'] ||= {}

      # Set the auth token
      #message['ext']['cookies'] = {'sid' : 'ARkAQII53wq3jGdDSELJHImS1as1xLEk2muofNjNaFY0KYWyoqC5VFTz1j2CpNPAP1bksgCBpq_K0FVLoXhP4gyYO2UizYe7'}

      # Carry on and send the message to the server
      callback.call(message)
    end
  end
  
  client.add_extension(ForceAuth.new)
  
              
  EM.run {
    client.subscribe('/foo') do |message|
      puts message.inspect
    end

    #client.publish('/foo', 'text' => 'Hello world')
  }
  
  
  haml :test
end
