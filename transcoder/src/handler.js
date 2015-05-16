console.log('Loading function');
var aws = require('aws-sdk');
var transcoder = new aws.ElasticTranscoder({apiVersion: '2012-09-25'});

exports.handler = function(event, context) {
  console.log('Received event:', JSON.stringify(event, null, 2));
  // Get the object from the event and show its content type
  var bucket = event.Records[0].s3.bucket.name;
  var key = event.Records[0].s3.object.key;

  var mediaId = key.replace(/\.[^/.]+$/, "");
  var outputs = null;
  if ( /A-[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}/i.test(mediaId) ) { /* Video */
    outputs = [
      {
        Key: mediaId + '/video.mp4',
        PresetId: '1431764878757-w37ugf' /* Chatanoo - MP4 */
      },
      {
        Key: mediaId + '/video.webm',
        PresetId: '1431765105700-dodtxt' /* Chatanoo - WebM */
      },
      {
        Key: mediaId + '/video.flv',
        PresetId: '1431765233842-9ulfbc' /* Chatanoo - WebM */
      }
    ];
  } else if ( /M-[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}/i.test(mediaId) ) { /* Audio */
    outputs = [
      {
        Key: mediaId + '/audio.mp3',
        PresetId: '1431766141904-lpijfs' /* Chatanoo - MP3 */
      },
      {
        Key: mediaId + '/audio.ogg',
        PresetId: '1431766187146-dooe52' /* Chatanoo - MP3 */
      }
    ];
  }

  if (!outputs) {
    context.succeed();
    return;
  }

  var params = {
    Input: {
      Key: key
    },
    PipelineId: '1431762470072-gnq6il', /* chatanoo */
    Outputs: outputs
  };

  transcoder.createJob(params, function(err, data) {
    if (err) {
      console.log(err, err.stack);
      context.fail('Error', "Error Creating Job: " + err);
    } else {
      console.log(data);
      context.succeed();
    }
  });
};