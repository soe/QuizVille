require 'sinatra'
require 'curb'
require 'json'
require 'cgi'

helpers do
end

def get_oauth_token
  # get oauth token
  c = Curl::Easy.http_post('https://login.salesforce.com/services/oauth2/token',
    'grant_type=password&client_id=3MVG9rFJvQRVOvk4cxTJa7DLkKTD8NuAg5AexmhUWE.Yv.W4.WgDugtPKYczI602iJPhbd6PI0w91GlaOSl_l&client_secret=4614924466188346354&username=soe%40soe.im.streamingapi&password=FORCE2012@@jSbIygQ9XKPulmIeEYPPI2lDl'
  )
  
  return JSON.parse(c.body_str)
end

def get_quizzes(user = false, date = "today")
  oauth_response = get_oauth_token

  if date == "today"
    date = "2012-02-23"
  end
  
  # SOQL query for Quick_Quiz__c 
  query = "SELECT Id, Name, Quiz_Date__c, Number_Correct__c, Total_Time__c, Member__r.Name FROM Quick_Quiz__c WHERE Quiz_Date__c = #{date}"
 
  if user
    query += " AND Member__r.Name = '#{user}'"
  end
  
  c = Curl::Easy.http_get("#{oauth_response['instance_url']}/services/data/v24.0/query?q=#{CGI::escape(query)}"
  ) do |curl|
    curl.headers['Authorization'] = "OAuth #{oauth_response['access_token']}"
  end
        
  return JSON.parse(c.body_str)
end

get '/' do
  # list out available quizzes taken by users by date or TODAY   
  quizzes = get_quizzes()
  
  @quizzes = quizzes['records']
  
  erb :index
end

get "/user/:user" do |user|
  # list out available quizzes taken by THE USER by date or TODAY    
  quizzes = get_quizzes(user)
  
  # should take only one
  quiz = quizzes['records'][0]
  
  # quiz['Member__r']['Name'] # user's name
  # quiz['Id'] # quiz id (cometd channel name)
  # quiz['Number_Correct__c'], quiz['Total_Time__c'], quiz['Quiz_Date__c']
  @quiz = quiz

  erb :user
end
