require('dotenv').load();

console.log 'Loading function'
_ = require('underscore')
mandrill = require('node-mandrill')( process.env.MANDRILL_KEY )

exports.handler = (event, context) ->
  console.log JSON.stringify(event, null, 2)
  console.log 'From SNS:', event.Records[0].Sns.Message

  message = JSON.parse(event.Records[0].Sns.Message)
  service = message.name
  session = message.session
  data = message.data

  ### Mes Idees Aussi ###
  if session is 8
    switch data.method
      when 'addItem'
        item = data.params[0]

        content = 'Une nouvelle contribution (' + item.id + ') à été ajoutée à la mosaïc'

        # ['carolannbraun@free.fr', 'mes-idees-aussi@cg94.fr']
        _([ 'mathieu.desve@me.com' ]).each (email) ->
          mandrill '/messages/send', { message:
            from_email: 'admin@chatanoo.org'
            to: [ { email: email } ]
            subject: '[Mes Idées Aussi] Nouvelle contribution'
            text: content }, (err, res) ->
            if err
              context.fail err
            else
              context.succeed()

      else
        context.succeed()