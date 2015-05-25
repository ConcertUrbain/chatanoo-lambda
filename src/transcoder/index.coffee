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
        { Key: "#{mediaId}/video.mp4",  PresetId: process.env.TRANSCODER__MP4_PRESET_ID }
        { Key: "#{mediaId}/video.webm", PresetId: process.env.TRANSCODER__WEBM_PRESET_ID }
        { Key: "#{mediaId}/video.flv",  PresetId: process.env.TRANSCODER__FLV_PRESET_ID }
      ]

    when /A-[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}/i.test(mediaId)
      outputs = [
        { Key: "#{mediaId}/audio.mp3", PresetId: process.env.TRANSCODER__MP3_PRESET_ID }
        { Key: "#{mediaId}/audio.ogg", PresetId: process.env.TRANSCODER__OGG_PRESET_ID }
      ]

    else
      return context.succeed()

  params =
    Input:
      Key: key
    PipelineId: process.env.TRANSCODER__PIPELINE_ID
    Outputs: outputs

  transcoder.createJob params, (err, data) ->
    if err
      console.log err, err.stack
      context.fail 'Error', 'Error Creating Job: ' + err
    else
      console.log data
      context.succeed()
