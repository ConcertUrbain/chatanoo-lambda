require('dotenv').load();
gm = require('gm').subClass( imageMagick: true )
async = require 'async'

aws = require 'aws-sdk'
s3 = new aws.S3();
transcoder = new aws.ElasticTranscoder(apiVersion: '2012-09-25')

exports.handler = (event, context) ->
  console.log 'Received event:', JSON.stringify(event, null, 2)

  # Get the object from the event and show its content type
  bucket = event.Records[0].s3.bucket.name
  key = event.Records[0].s3.object.key

  outputBucket = process.env.TRANSCODER__OUTPUT_BUCKET

  mediaId = key.replace(/\.[^/.]+$/, '')
  transcoderType = null
  switch true
    when /M-[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}/i.test(mediaId)
      transcoderType = 'video'
      outputs = [
        { Key: "#{mediaId}/video.mp4",  PresetId: process.env.TRANSCODER__MP4_PRESET_ID }
        { Key: "#{mediaId}/video.webm", PresetId: process.env.TRANSCODER__WEBM_PRESET_ID }
        { Key: "#{mediaId}/video.flv",  PresetId: process.env.TRANSCODER__FLV_PRESET_ID }
      ]

    when /A-[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}/i.test(mediaId)
      transcoderType = 'audio'
      outputs = [
        { Key: "#{mediaId}/audio.mp3", PresetId: process.env.TRANSCODER__MP3_PRESET_ID }
        { Key: "#{mediaId}/audio.ogg", PresetId: process.env.TRANSCODER__OGG_PRESET_ID }
      ]

    when /P-[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}/i.test(mediaId)
      transcoderType = 'image'

    else
      console.log 'No actions'
      return context.succeed()

  if transcoderType in ['video', 'audio'] and outputs
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

  else if transcoderType is 'image'
    async.waterfall [
        (next)-> s3.getObject({ Bucket: bucket, Key: key }, next)
        (res, next)->
          gm(res.Body).size (err, size)->
            scalingFactor = Math.min(
              parseInt(process.env.TRANSCODER__MAX_WIDTH) / size.width,
              parseInt(process.env.TRANSCODER__MAX_HEIGHT) / size.height
            )
            width  = scalingFactor * size.width;
            height = scalingFactor * size.height;
            @resize(width, height).toBuffer 'png', (err, buffer)->
              next(err) if err
              next(null, res.ContentType, buffer)
        (contentType, data, next)->
          params =
            Bucket: outputBucket
            Key: "#{mediaId}/image.png"
            Body: data
            ContentType: contentType
          s3.putObject(params, next)
      ], (err)->
        if err
          console.log err, err.stack
          context.fail 'Error', 'Error Creating Job: ' + err
        else
          context.succeed()

  else
    console.log 'No actions'
    return context.succeed()
