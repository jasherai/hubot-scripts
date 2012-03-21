# Returns error info from Errbit
#
# hubot show me errbit errors - Get the most recent active errors
jsdom = require 'jsdom'
env = process.env

# ENV Variables required  :
# HUBOT_ERRBIT_AUTH_TOKEN : Auth token from your account ( Login to site and go to 'Settings' )
# HUBOT_ERRBIT_URL        : Account name (eg: http://<account name>.errbitapp.com)

# Add to heroku :
# % heroku config:add HUBOT_ERRBIT_AUTH_TOKEN="..."
# % heroku config:add HUBOT_ERRBIT_URL="..."
# Example error and further API :
# http://help.errbit.io/kb/api-2/api-overview

module.exports = (robot) ->

  robot.respond /(show me )?errbit( errors)?(.*)/i, (msg) ->
    query msg, (body, err, project_name) ->
      return msg.send err if err


      error_groups = body.getElementsByTagName("group")
      return msg.send "Congrats! No errors in the system right now!" unless error_groups?

      output = "#{error_groups.length} recent errors found :"

      for group in error_groups
        most_recent_at = group.getElementsByTagName("most-recent-notice-at")[0].innerHTML
        created_at    = group.getElementsByTagName("created-at")[0].innerHTML
        updated_at    = group.getElementsByTagName("updated-at")[0].innerHTML
        notices_count = group.getElementsByTagName("notices-count")[0].innerHTML

        error_id      = group.getElementsByTagName("id")[0].innerHTML
        error_class   = group.getElementsByTagName("error-class")[0].innerHTML
        error_message = group.getElementsByTagName("error-message")[0].innerHTML
        resolved      = group.getElementsByTagName("resolved")[0].innerHTML

        file          = group.getElementsByTagName("file")[0].innerHTML
        rails_env     = group.getElementsByTagName("rails-env")[0].innerHTML
        line_number   = group.getElementsByTagName("line-number")[0].innerHTML

        error_url     = "#{errbit_url}/errs/#{error_id}"

        output += "\n****"
        output += "\n* ##{error_id}(#{notices_count}) : Last error @ #{most_recent_at}"
        output += "\n* #{rails_env} - #{error_class} : #{error_message}"
        output += "\n* #{error_url} => #{file}:#{line_number}"

      msg.send output
      msg.send "\n****"


  getDom = (xml) ->
    body = jsdom.jsdom(xml)
    throw Error("No XML data returned.") if body.getElementsByTagName("group")[0].childNodes.length == 0
    body

  query = (msg, cb) ->
    errbit_auth_key = process.env.HUBOT_ERRBIT_AUTH_TOKEN
    errbit_url  = process.env.HUBOT_ERRBIT_URL

    unless errbit_auth_key
       msg.send "Errbit auth token isn't set. Please retrieve your auth token."
       msg.send "Then set the HUBOT_ERRBIT_AUTH_TOKEN environment variable"
       return

    unless errbit_url
       msg.send "You haven't set the full url to your errbit instance. Please enter the full url here.[ http://errbit-app-name.com ]"
       msg.send "Then set the HUBOT_ERRBIT_URL environment variable"
       return

    msg.http("#{errbit_url}/errs.xml")
      .query(auth_token: errbit_auth_key)
      .get() (err, res, body) ->
        try
          body = getDom body
        catch err
          err = "Could not fetch errbit errors."
        cb(body, err, errbit_url)


