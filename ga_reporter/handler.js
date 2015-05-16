console.log('Loading function');
var ua = require('universal-analytics');

exports.handler = function(event, context) {
    console.log(JSON.stringify(event, null, 2));
    console.log('From SNS:', event.Records[0].Sns.Message);
    
    var message = JSON.parse( event.Records[0].Sns.Message );
    var service = message.name; 
    var data = message.data; 
    
    console.log( service + ": " + data.method + " by " + data.byUser );
    visitor = ua('UA-44078448-1', data.byUser)
	visitor.event(service, data.method).send()
    
    context.succeed();
};