require 'sinatra'
require 'curb'
require 'json'
require 'cgi'

helpers do
end

def get_oauth_token
  # get oauth token
  c = Curl::Easy.http_post('https://login.salesforce.com/services/oauth2/token',
    'grant_type=password&client_id='+ ENV['CLIENT_ID'] +'&client_secret='+ ENV['CLIENT_SECRET'] +'&username='+ ENV['USERNAME'] +'&password='+ ENV['PASSWORD'] +''
  )
  
  return JSON.parse(c.body_str)
end

def get_quizzes(user = false, date = "today")
  if date == "today"
    date = Date.today
  end
  
  # SOQL query for Quick_Quiz__c 
  query = "SELECT Id, Name, Quiz_Date__c, Number_Correct__c, Total_Time__c, Member__r.Name FROM Quick_Quiz__c WHERE Quiz_Date__c = #{date}"
 
  if user
    query += " AND Member__r.Name = '#{user}'"
  end
  
  return do_curl(query)    
end

def get_answers(user = false, date = "today")
  if date == "today"
    date = "2012-02-23"
  end
  
  # SOQL query for Quick_Quiz_Answer__c 
  query = "SELECT Id, Name, Language__c, Is_Correct__c, Time__c, Quick_Quiz__c, Quick_Quiz__r.Member__r.Name FROM Quick_Quiz_Answer__c WHERE Quick_Quiz__r.Quiz_Date__c = #{date}"
 
  if user
    query += " AND Quick_Quiz__r.Member__r.Name = '#{user}'"
  end
  
  query += " LIMIT 10"
  
  return do_curl(query) 
end

def do_curl(query)
  oauth_response = get_oauth_token
  
  c = Curl::Easy.http_get("#{oauth_response['instance_url']}/services/data/v24.0/query?q=#{CGI::escape(query)}"
  ) do |curl|
    curl.headers['Authorization'] = "OAuth #{oauth_response['access_token']}"
  end
  
  r = JSON.parse(c.body_str)
  
  return r
end


get '/' do
  # list out recent answers taken by users by date or TODAY  
   
  #"Quick_Quiz__r"=>{"Member__r"=>{"Name"=>"John", "attributes"=>{"url"=>"/services/data/v24.0/sobjects/Member__c/a00d0000002jBvOAAU", "type"=>"Member__c"}}, 
  #"attributes"=>{"url"=>"/services/data/v24.0/sobjects/Quick_Quiz__c/a02d0000002cUvKAAU", "type"=>"Quick_Quiz__c"}}, 
  #"Language__c"=>"Java", "Is_Correct__c"=>true, "Name"=>"QUIZA-0024", 
  #"attributes"=>{"url"=>"/services/data/v24.0/sobjects/Quick_Quiz_Answer__c/a01d0000002j60oAAA", "type"=>"Quick_Quiz_Answer__c"}, 
  #"Time__c"=>20.0, "Id"=>"a01d0000002j60oAAA", "Quick_Quiz__c"=>"a02d0000002cUvKAAU"
  answers = get_answers()
  
  @answers = answers['records']
  
  erb :index
end

get "/user/demo" do
  
  erb :user_demo
end

get "/user/:user" do |user|
  # list out available quizzes taken by THE USER by date or TODAY    
  quizzes = get_quizzes(user)
    
  if quizzes['records'] == []
    @user = user
    
    erb :user_blank
  else
    # should take only one - then subscribe to get quiz
    quiz = quizzes['records'][0]
  
    # quiz['Member__r']['Name'] # user's name
    # quiz['Id'] # quiz id (cometd channel name)
    # quiz['Number_Correct__c'], quiz['Total_Time__c'], quiz['Quiz_Date__c']
    @quiz = quiz
    
    #"Quick_Quiz__r"=>{"Member__r"=>{"Name"=>"John", "attributes"=>{"url"=>"/services/data/v24.0/sobjects/Member__c/a00d0000002jBvOAAU", "type"=>"Member__c"}}, 
    #"attributes"=>{"url"=>"/services/data/v24.0/sobjects/Quick_Quiz__c/a02d0000002cUvKAAU", "type"=>"Quick_Quiz__c"}}, 
    #"Language__c"=>"Java", "Is_Correct__c"=>true, "Name"=>"QUIZA-0024", 
    #"attributes"=>{"url"=>"/services/data/v24.0/sobjects/Quick_Quiz_Answer__c/a01d0000002j60oAAA", "type"=>"Quick_Quiz_Answer__c"}, 
    #"Time__c"=>20.0, "Id"=>"a01d0000002j60oAAA", "Quick_Quiz__c"=>"a02d0000002cUvKAAU"
    answers = get_answers()
    
    @answers = answers['records']
    
    erb :user
  end
end
