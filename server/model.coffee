Sequelize = require("sequelize")
sequelize = new Sequelize 'database_name', '', '',
  dialect: "sqlite"
  storage: 'database.sqlite'
sequelize
  .authenticate()
  .complete (err) ->
    if !!err
      console.log('Unable to connect to the database:', err)
    else
      console.log('Connection has been established successfully.')
CacheMeta = sequelize.define 'CacheMeta',
  url: Sequelize.STRING
  size: Sequelize.INTEGER.UNSIGNED
  etag: Sequelize.STRING
  expired_at: Sequelize.DATETIME

Post = sequelize.define 'Post',
  uuid: Sequelize.STRING
