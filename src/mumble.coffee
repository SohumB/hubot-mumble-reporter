# Description:
#   Reports mumble events in chat
#
# Commands:
#

mumble = require 'mumble'
host = process.env.HUBOT_MUMBLE_HOSTNAME
server = "mumble://#{host}"
url = "#{server}?version=1.2.0"
channel = process.env.HUBOT_MUMBLE_CHANNEL || '#general'

module.exports = (robot) ->
  mumble.connect server, {}, (error, connection) ->
    if (error)
      throw new Error(error);

    connection.authenticate robot.name
    connection.on 'user-move', (user) ->
      mumbleChannel = user.channel.name
      robot.messageRoom channel, "#{user.name} just joined #{mumbleChannel} #{url}&title=#{encodeURIComponent(mumbleChannel)}"

  robot.router.post '/hubot/mumble', (req, res) ->
    data = req.body
    respond = data.channel_name
    user = data.user_name

    helptext = "go to http://sourceforge.net/projects/mumble/ , download and install the msi, then click #{url}"

    help = data.text.match(/help/)

    robot.http("http://#{host}/mumble-django/mumble/1.json")
      .header('Accept', 'application/json')
      .get() (err, res, body) ->
        try
          if (err)
            throw err

          root = JSON.parse(body).root

          lines = []

          visit = (channel) ->
            namesPlusBot = channel.users.map (user) -> user.name
            names = namesPlusBot.filter (name) -> name != robot.name
            if names.length > 0
              namesStr = if names.length == 2 then names.join ' and ' else names.join ', '
              verb = if names.length == 1 then 'is' else 'are'
              lines.push "#{namesStr} #{verb} hanging out in #{channel.name}"
            channel.channels.forEach visit

          visit root

          if lines.length == 0
            lines = ["No one's online though :("]

          msg = if help
            "@#{user}, #{helptext}\n#{lines.join("\n")}"
          else
            "@#{user}, #{url} is up! \n#{lines.join("\n")}"

          robot.messageRoom respond, msg
        catch e
          console.log e
          msg = if help
            "@#{user}, #{helptext}\nBut, the server appears to be down :("
          else
            "@#{user}, Mumble appears to be down :("

          robot.messageRoom respond, msg

      res.status(200).send()
