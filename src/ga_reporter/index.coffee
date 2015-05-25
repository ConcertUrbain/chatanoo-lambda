require('dotenv').load();

console.log 'Loading function'
ua = require('universal-analytics')

exports.handler = (event, context) ->
  console.log JSON.stringify(event, null, 2)
  console.log 'From SNS:', event.Records[0].Sns.Message

  message = JSON.parse(event.Records[0].Sns.Message)
  service = message.name
  data = message.data

  console.log service + ': ' + data.method + ' by ' + data.byUser
  visitor = ua(process.env.GA_REPORTER__GA_AU_ID, data.byUser)
  visitor.event(service, data.method).send()

  context.succeed()
