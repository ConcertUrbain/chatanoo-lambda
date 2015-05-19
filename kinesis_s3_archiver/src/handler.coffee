require('dotenv').load();
_ = require('underscore')
moment = require('moment')
uuid = require('node-uuid')

aws = require 'aws-sdk'
s3 = new aws.S3()

exports.handler = (event, context) ->
  console.log JSON.stringify(event, null, 2)

  now = moment()
  data = _(event.Records).map (record)->
    m = JSON.parse( new Buffer(record.kinesis.data, 'base64').toString('utf8') )
    params = JSON.parse( m.data.params )
    JSON.stringify
      service: m.name
      session: m.session
      method: m.data.method
      params_1: params[0]
      params_2: params[1]
      params_3: params[2]
      params_4: params[3]

  params =
    Bucket: process.env.S3_BUCKET
    Key: "tmp/#{now.toISOString()}-#{uuid.v4()}"
    Body: data.join('\r\n')

  s3.putObject params, (err, data)->
    if err
      console.log err, err.stack
      context.fail(err);
    else
      context.succeed(data);
