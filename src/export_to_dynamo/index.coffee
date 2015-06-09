require('dotenv').load()

_ = require 'underscore'
async = require 'async'

aws = require 'aws-sdk'
dynamodb = require('dynamodb').ddb
  accessKeyId: process.env.AWS_ACCESS_KEY_ID
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY

mysql = require('mysql').createConnection
  host: process.env.EXPORT_TO_DYNAMO__MYSQL_RDS_HOST
  port: process.env.EXPORT_TO_DYNAMO__MYSQL_RDS_PORT
  database: process.env.EXPORT_TO_DYNAMO__MYSQL_RDS_DB
  user: process.env.EXPORT_TO_DYNAMO__MYSQL_RDS_USER
  password: process.env.EXPORT_TO_DYNAMO__MYSQL_RDS_PASS

dbname = process.env.EXPORT_TO_DYNAMO__DYNAMO_DB

getItem = (id, callback)->
  mysql.query """
    SELECT *
    FROM items
    WHERE id = #{id};
  """, (err, rows)->
    return callback(err) if err
    callback(null, rows[0])

getMedias = (id, callback)->
  types = ['Picture', 'Sound', 'Text', 'Video']
  requests = _(types).map (type)->
    (cb)->
      mysql.query """
        SELECT *
        FROM medias_assoc
          RIGHT JOIN medias_#{type.toLowerCase()}
            ON (`medias_assoc`.`medias_id` = `medias_#{type.toLowerCase()}`.`id` AND `medias_assoc`.`mediaType` = '#{type}')
        WHERE `medias_assoc`.`assoc_id` = #{id}
        AND `medias_assoc`.`assocType` = 'Item';
      """, (err, rows)->
        cb(err, rows)

  async.parallel requests, (err, rows)->
    callback( err, _(types).object(rows) )

getComments = (id, callback)->
  mysql.query """
    SELECT *
    FROM comments
    WHERE items_id = #{id};
  """, (err, comments)->
    getDatas 'Comment', _(comments).pluck('id'), (err, datas)->
      _(comments).each (c)->
        c.datas =
          Adress: _(datas.Adress).where(datas_id: c.id)
          Carto: _(datas.Carto).where(datas_id: c.id)
          Vote: _(datas.Vote).where(datas_id: c.id)
      callback(err, comments)

getUsers = (ids, callback)->
  mysql.query """
    SELECT *
    FROM users
    WHERE id IN (#{ids.join(',')});
  """, callback

getDatas = (type, ids, callback)->
  types = ['Adress', 'Carto', 'Vote']
  requests = _(types).map (_type)->
    (cb)->
      mysql.query """
        SELECT *
        FROM datas_assoc
          RIGHT JOIN datas_#{_type.toLowerCase()}
            ON (`datas_assoc`.`datas_id` = `datas_#{_type.toLowerCase()}`.`id` AND `datas_assoc`.`dataType` = '#{_type}')
        WHERE `datas_assoc`.`assoc_id` IN (#{ids.join(',')})
        AND `datas_assoc`.`assocType` = '#{type}';
      """, (err, rows)->
        cb(err, rows)

  async.parallel requests, (err, rows)->
    callback( err, _(types).object(rows) )

error = (err)->
  console.log err, err.stack
  context.fail(err)

exports.handler = (event, context) ->
  console.log 'Received event:', JSON.stringify(event, null, 2)

  id = 1930
  # id = 2039

  usersId = []
  getItem id, (err, item)->
    return error(err) if err

    usersId.push(item.users_id)
    async.parallel {
      datas: (cb)-> getDatas('Item', [id], cb)
      medias: (cb)-> getMedias(id, cb)
      comments: (cb)->
        getComments id, (err, comments)->
          _(comments).each( (c)-> usersId.push(c.users_id) )
          cb(err, comments)
    }, (err, results)->
      getUsers usersId, (err, users)->
        item.user = _(users).findWhere(id: item.users_id)
        item.datas = results.datas
        item.medias = results.medias
        item.comments = _(results.comments).each (c)->
          c.user = _(users).findWhere(id: c.users_id)

        dynamodb.putItem(dbname, item, {}, console.log)
