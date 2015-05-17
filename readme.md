## Chatanoo Lambda Functions

### Build

Install Gulp

```
npm install -g gulp
```

Go to the right folder

```
cd [MY_FUNCTION]
```

List of functions:

* GA Reporter
* Mailer
* Transcoder

Build the function

```
gulp build
```

### Deployment

In staging, for each project (builded before)

```
gulp deploy
```

In Production, for each project (builded before)

```
ENV=production gulp deploy
```

### Lambda Tools

Update Lambda Function Configuration

```
gulp update
```

or

```
ENV=production gulp update
```