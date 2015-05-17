require('dotenv').load();

aws = require 'aws-sdk'
transcoder = new aws.ElasticTranscoder(apiVersion: '2012-09-25')

exports.handler = (event, context) ->
  console.log 'Received event:', JSON.stringify(event, null, 2)

  # Get the object from the event and show its content type
  bucket = event.Records[0].s3.bucket.name
  key = event.Records[0].s3.object.key

  mediaId = key.replace(/\.[^/.]+$/, '')
  switch true
    when /M-[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}/i.test(mediaId)
      outputs = [
        { Key: "#{mediaId}/video.mp4",  PresetId: '1431764878757-w37ugf'}
        { Key: "#{mediaId}/video.webm", PresetId: '1431765105700-dodtxt'}
        { Key: "#{mediaId}/video.flv",  PresetId: '1431765233842-9ulfbc'}
      ]

    when /A-[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}/i.test(mediaId)
      outputs = [
        { Key: "#{mediaId}/audio.mp3", PresetId: '1431766141904-lpijfs'}
        { Key: "#{mediaId}/audio.ogg", PresetId: '1431766187146-dooe52'}
      ]

    else
      return context.succeed()
    
  params = 
    Input: 
      Key: key
    PipelineId: '1431762470072-gnq6il'
    Outputs: outputs

  transcoder.createJob params, (err, data) ->
    if err
      console.log err, err.stack
      context.fail 'Error', 'Error Creating Job: ' + err
    else
      console.log data
      context.succeed()