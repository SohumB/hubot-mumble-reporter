# Description:
#   Reports mumble events in chat
#
# Commands:
#

mumble = require 'mumble'
host = process.env.HUBOT_MUMBLE_HOSTNAME
server = "mumble://#{host}"
url = "#{server}?version=1.2.0"
defaultChannel = process.env.HUBOT_MUMBLE_DEFAULT_CHANNEL || '#general'
channelsToIgnore = (process.env.HUBOT_MUMBLE_CHANNELS_TO_IGNORE || "Root").split(" ")

module.exports = (robot) ->
  mumble.connect server, {}, (error, connection) ->
    if (error)
      throw new Error(error);

    connection.authenticate robot.name
    connection.on 'user-move', (user) ->
      mumbleChannel = user.channel.name
      if (!channelsToIgnore.contains(mumbleChannel))
        channel = if (mumbleChannel.slice(0,1) == "#") then mumbleChannel else defaultChannel
        robot.messageRoom channel, "#{user.name} just joined #{url}&title=#{encodeURIComponent(mumbleChannel)}"

  robot.respond /mumble( (help|status))?/, (res) ->
    help = res.match[2] == "help"

    helptext = "go to http://sourceforge.net/projects/mumble/ , download and install the msi, then click #{url}"

    robot.http("http://#{host}/mumble-django/mumble/1.json")
      .header('Accept', 'application/json')
      .get() (err, res2, body) ->
        try
          if (err)
            throw err

          root = JSON.parse(body).root

          lines = []

          visit = (channel) ->
            if (!channelsToIgnore.contains(channel.name))
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
            "#{helptext}\n#{lines.join("\n")}"
          else
            "#{url} is up! \n#{lines.join("\n")}"

          res.send msg
        catch e
          console.log e
          msg = if help
            "#{helptext}\nBut, the server appears to be down :("
          else
            "Mumble appears to be down :("

          res.send msg
