# Description:
#   Display current app performance stats from New Relic
#
# Dependencies:
#   "xml2js": "0.1.14"
#
# Configuration:
#   HUBOT_NEWRELIC_ACCOUNT_ID
#   HUBOT_NEWRELIC_APP_ID
#   HUBOT_NEWRELIC_API_KEY
# 
# Commands:
#   hubot newrelic me - Returns summary application stats from New Relic
#
# Notes:
#   How to find these settings:
#   After signing into New Relic, select your application
#   Given: https://rpm.newrelic.com/accounts/xxx/applications/yyy
#     xxx is your Account ID and yyy is your App ID
#   Account Settings > API + Web Integrations > API Access > "API key"
# 
# Author:
#   briandoll

module.exports = (robot) ->
  robot.respond /newrelic me/i, (msg) ->
    accountId = process.env.HUBOT_NEWRELIC_ACCOUNT_ID
    appId     = process.env.HUBOT_NEWRELIC_APP_ID
    apiKey    = process.env.HUBOT_NEWRELIC_API_KEY
    xml2js = require("xml2js")
    parser = new xml2js.Parser(xml2js.defaults["0.1"])
    request_headers = {
        'x-api-key': apiKey
    }

    msg.http("https://rpm.newrelic.com/accounts/#{accountId}/applications/#{appId}/threshold_values.xml")
      .headers("x-api-key": apiKey)
      .get() (err, res, body) ->
        if err
          msg.send "New Relic says: #{err}"
          return

        parser.parseString body, (err, json)->
          threshold_values = json['threshold_value'] || []
          lines = threshold_values.map (threshold_value) ->
            "#{threshold_value['@']['name']}: #{threshold_value['@']['formatted_metric_value']}"
             
          msg.send lines.join("\n"), "https://rpm.newrelic.com/accounts/#{accountId}/applications/#{appId}"
