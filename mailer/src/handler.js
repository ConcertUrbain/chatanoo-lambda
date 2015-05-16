console.log('Loading function');
var _ = require('underscore');
var mandrill = require('node-mandrill')('c94rNO7vJBGKY4cWeAENDw');

exports.handler = function(event, context) {
    console.log(JSON.stringify(event, null, 2));
    console.log('From SNS:', event.Records[0].Sns.Message);
    
    var message = JSON.parse( event.Records[0].Sns.Message );
    var service = message.name;
    var session = message.session;
    var data = message.data;
    
    /* Mes Idees Aussi */
    if ( session == 8 ) {
        switch (data.method) {
            case "addItem":
                var item = data.params[0];
                content = "Une nouvelle contribution (" + item.id + ") à été ajoutée à la mosaïc";

                // ['carolannbraun@free.fr', 'mes-idees-aussi@cg94.fr']
                _( ['mathieu.desve@me.com'] ).each( function(email) {

                    mandrill( '/messages/send', {
                        message: {
                            from_email: 'admin@chatanoo.org',
                            to: [
                                { email: email }
                            ],
                            subject: '[Mes Idées Aussi] Nouvelle contribution',
                            text: content
                        }
                    }, function (err, res) {
                        if (err) {
                            context.fail(err);
                        } else {
                            context.succeed();
                        }
                    });
                });
                break;
            default:
                context.succeed();
                break;
        }
    }

};