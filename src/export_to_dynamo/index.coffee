require('dotenv').load()

_ = require 'underscore'
async = require 'async'

aws = require 'aws-sdk'
mysql = require('mysql').createConnection
  host: process.env.EXPORT_TO_DYNAMO__MYSQL_RDS_HOST
  port: process.env.EXPORT_TO_DYNAMO__MYSQL_RDS_PORT
  db: process.env.EXPORT_TO_DYNAMO__MYSQL_RDS_DB
  user: process.env.EXPORT_TO_DYNAMO__MYSQL_RDS_USER
  pass: process.env.EXPORT_TO_DYNAMO__MYSQL_RDS_PASS

getItem = (id)->
  mysql.query """
    SELECT *
    FROM items
    WHERE id = #{id};
  """, (err, rows)->

getMedias = (id, callback)->
  requests = _(['Picture', 'Sound', 'Text', 'Video']).map (type)->
    (cb)->
      mysql.query """
        SELECT *
        FROM medias_assoc
          RIGHT JOIN medias_#{type.toLowerCase()}
            ON (`medias_assoc`.`medias_id` = `medias_#{type.toLowerCase()}`.`id` AND `medias_assoc`.`dataType` = '#{type}')
        WHERE `medias_assoc`.`medias_id` IN (#{ids.join(',')}) ;
      """, cb

  async.parallel requests, (err, row)->
    callback( err, _(rows).flatten() )

getComments = (id, callback)->
  mysql.query """
    SELECT *
    FROM comments
    WHERE items_id = #{id};
  """, (err, comments)->
    getDatas 'Comment', _(comments).pluck('id'), (err, datas)->
      _(comments).each (c)->
        comments.datas = _(datas).where(datas_id: comments.id)
      callback(err, comments)

getUsers = (ids, callback)->
  mysql.query """
    SELECT *
    FROM users
    WHERE id IN (#{ids.join(',')});
  """, callback

getDatas = (type, ids, callback)->
  requests = _(['Adress', 'Carto', 'Vote']).map (type)->
    (cb)->
      mysql.query """
        SELECT *
        FROM datas_assoc
          RIGHT JOIN datas_#{type.toLowerCase()}
            ON (`datas_assoc`.`datas_id` = `datas_#{type.toLowerCase()}`.`id` AND `datas_assoc`.`dataType` = '#{type}')
        WHERE `datas_assoc`.`assocType` = '#{type}'
        WHERE `datas_assoc`.`datas_id` IN (#{ids.join(',')});
      """, cb

  async.parallel requests, (err, rows)->
    callback( err, _(rows).flatten() )

exports.handler = (event, context) ->
  console.log 'Received event:', JSON.stringify(event, null, 2)

  id = 1

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
        item.datas = datas
        item.medias = medias
        item.comments = _(comments).map (c)->
          c.user = _(users).findWhere(id: c.users_id)

        # TODO
