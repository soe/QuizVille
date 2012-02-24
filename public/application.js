$(function() {
  var channel = $('#channel').text();

  var cometd = new Faye.Client('http://quizville-cometd.herokuapp.com/cometd', {timeout: 120});
  cometd.disable('websocket');
  
  if(channel) {
    var subscription = cometd.subscribe(channel, function(message) {
      console.log(message);
      $('#answers').append(message);
      alert(message);
    });
    subscription.callback(function() {
      console.log('Subscription is now active!');
    });
    subscription.errback(function(error) {
      console.log(error.message);
    });
  }
  
  var demo_publish = function() {
    console.log('demo_publish');
    cometd.publish("/q/demo", 
      {"Name":"QUIZA-0040","Quick_Quiz__c":"a02d0000002cUvKAAU","Id":"a01d0000002j7RFAAY"}
    );
  };
  
  if(channel == '/q/demo') {
    setInterval (demo_publish, 20000);
  }
});
