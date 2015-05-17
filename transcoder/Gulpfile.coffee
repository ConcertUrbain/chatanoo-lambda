gulp = require('gulp')
gutil = require('gulp-util')
modify = require('gulp-modify')
yaml = require('js-yaml')
del = require('del')
rename = require('gulp-rename')
install = require('gulp-install')
zip = require('gulp-zip')
AWS = require('aws-sdk')
fs = require('fs')
coffee = require('gulp-coffee')
runSequence = require('run-sequence')
_ = require('underscore')

configFile = if process.env.ENV 
  "./config-#{process.env.ENV}.yml" 
else 
  './config-staging.yml'

# First we need to clean out the dist folder and remove the compiled zip file.
gulp.task 'clean', (cb) ->
  del './dist', del('./archive.zip', cb)

# The js task could be replaced with gulp-coffee as desired.
gulp.task 'coffee', ->
  gulp.src('./src/**/*.coffee')
    .pipe coffee(bare: true).on('error', gutil.log)
    .pipe gulp.dest('dist/')

gulp.task 'dist', ->
  gulp.src(['./src/**/*', '!./src/**/*.coffee'])
    .pipe gulp.dest('dist/')

# Here we want to install npm packages to dist, ignoring devDependencies.
gulp.task 'npm', ->
  gulp.src('./package.json')
    .pipe gulp.dest('./dist/')
    .pipe install(production: true)

# Next copy over environment variables managed outside of source control.
gulp.task 'env', ->
  gulp.src(configFile)
    .pipe modify( fileModifier: (file)-> yaml.load(file.contents).env.join('\r\n') )
    .pipe rename('.env')
    .pipe gulp.dest('./dist')

# Now the dist directory is ready to go. Zip it.
gulp.task 'zip', ->
  gulp.src([
    'dist/**/*'
    '!dist/package.json'
    'dist/.*'
  ])
    .pipe zip('dist.zip')
    .pipe gulp.dest('./')

# Per the gulp guidelines, we do not need a plugin for something that can be
# done easily with an existing node module. #CodeOverConfig
#
# Note: This presumes that AWS.config already has credentials. This will be
# the case if you have installed and configured the AWS CLI.
#
# See http://aws.amazon.com/sdk-for-node-js/
gulp.task 'update', ->
  config = yaml.load fs.readFileSync(configFile, 'utf8')

  AWS.config.region = config.region
  AWS.config.credentials = new AWS.SharedIniFileCredentials( profile: config.profile )
  lambda = new AWS.Lambda( apiVersion: '2015-03-31' )

  params = 
    FunctionName: config.lambda.name
    Description: config.lambda.description
    Handler: config.lambda.handler
    MemorySize: config.lambda.memory_size,
    Role: config.iam.role.name
    Timeout: config.lambda.timeout

  lambda.updateFunctionConfiguration params, (err, data) ->
      gutil.log(err) if err

gulp.task 'update-events-source', ->
  config = yaml.load fs.readFileSync(configFile, 'utf8')

  AWS.config.region = config.region
  AWS.config.credentials = new AWS.SharedIniFileCredentials( profile: config.profile )
  lambda = new AWS.Lambda( apiVersion: '2015-03-31' )

  lambda.listEventSourceMappings { FunctionName: config.lambda.name }, (err, data)->
    return gutil.log(err) if err

    for eventSource in data['EventSourceMappings']
      lambda.deleteEventSourceMapping eventSource, (err, data) ->
          gutil.log(err) if err

    for eventSource in config.lambda.event_sources
      params = 
        EventSourceArn: eventSource.arn
        FunctionName: config.lambda.name
        StartingPosition: 'LATEST'

      params['BatchSize'] = eventSource.batch_size if eventSource.batch_size
      params['Enabled'] = eventSource.enabled if eventSource.enabled

      lambda.createEventSourceMapping params, (err, data) ->
          gutil.log(err) if err

gulp.task 'upload', ->
  config = yaml.load fs.readFileSync(configFile, 'utf8')

  AWS.config.region = config.region
  AWS.config.credentials = new AWS.SharedIniFileCredentials( profile: config.profile )
  lambda = new AWS.Lambda( apiVersion: '2015-03-31' )

  params = 
    FunctionName: config.lambda.name
    ZipFile: new Buffer(fs.readFileSync('./dist.zip'))

  lambda.updateFunctionCode params, (err, data) ->
    if err
      warning = 'Package upload failed. '
      warning += 'Check your iam:PassRole permissions.'
      gutil.log warning
      gutil.log err

# The key to deploying as a single command is to manage the sequence of events.
gulp.task 'default', (callback) ->
  runSequence(
    [ 'clean' ], 
    [ 'coffee', 'dist', 'npm', 'env'], 
    [ 'zip' ], 
    [ 'upload' ], 
    callback
  )

gulp.task 'build', (callback) ->
  runSequence(
    [ 'clean' ], 
    [ 'coffee', 'dist', 'npm', 'env'], 
    callback
  )

gulp.task 'deploy', (callback) ->
  runSequence(
    [ 'env' ],
    [ 'zip' ], 
    [ 'upload' ], 
    callback
  )