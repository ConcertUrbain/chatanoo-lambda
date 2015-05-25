## Chatanoo Lambda Functions

### Build

Install Gulp

```
npm install -g gulp
```

List of functions:

* GA Reporter
* Mailer
* Transcoder
* MergeS3Logs
* KinesisS3Archiver
* ExportToDynamo

Build the function

```
gulp build
```

### Deployment

In staging, for each project (builded before)

```
gulp deploy --function [FUNCTION]
```

In Production, for each project (builded before)

```
gulp deploy --function [FUNCTION] --production
```

### Lambda Tools

Update Lambda Function Configuration

```
gulp update --function [FUNCTION]
```

or

```
gulp update --function [FUNCTION] --production
```
