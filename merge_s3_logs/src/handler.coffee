require('dotenv').load();
_ = require('underscore')
moment = require('moment')
uuid = require('node-uuid')
async = require('async')

aws = require 'aws-sdk'
s3 = new aws.S3()

exports.handler = (event, context) ->
  console.log JSON.stringify(event, null, 2)

  now = moment()
  params =
    Bucket: process.env.S3_BUCKET
    Marker: 'tmp/'

  s3.listObjects params, (err, data)->
    if err
      console.log err, err.stack
      context.fail(err)
      return
    return context.succeed() if data.Contents.length is 0

    getFiles = _(data.Contents).map (file)->
      (cb)->
        params =
          Bucket: process.env.S3_BUCKET
          Key: file.Key

        s3.getObject params, (err, data)->
          return cb(err) if err
          cb(null, new Buffer(data.Body, 'base64').toString('utf8'))

    deleteFiles = _(data.Contents).map (file)->
      (cb)->
        params =
          Bucket: process.env.S3_BUCKET
          Key: file.Key

        s3.deleteObject params, (err, data)->
          cb(err, data)

    async.parallel getFiles, (err, data)->
      if err
        console.log err, err.stack
        context.fail(err)
        return

      params =
        Bucket: process.env.S3_BUCKET
        Key: "logs/#{now.format('YYYY-MM-DD')}/#{now.toISOString()}-#{uuid.v4()}"
        Body: data.join('\r\n')

      s3.putObject params, (err, data)->
        if err
          console.log err, err.stack
          context.fail(err)
          return

        async.parallel deleteFiles, (err, data)->
          if err
            console.log err, err.stack
            context.fail(err)
          else
            context.succeed()
