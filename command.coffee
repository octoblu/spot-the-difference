colors   = require 'colors/safe'
dashdash = require 'dashdash'
_        = require 'lodash'
{diffString}   = require 'json-diff'

packageJSON = require './package.json'

OPTIONS = [{
  names: ['help', 'h']
  type: 'bool'
  help: 'Print this help and exit.'
}, {
  names: ['version', 'v']
  type: 'bool'
  help: 'Print the version and exit.'
}]

class Command
  constructor: ->
    process.on 'uncaughtException', @die
    {@items} = @parseOptions()

  parseOptions: =>
    parser = dashdash.createParser({options: OPTIONS})
    options = parser.parse(process.argv)

    if options.help
      console.log @usage parser.help({includeEnv: true})
      process.exit 0

    if options.version
      console.log packageJSON.version
      process.exit 0

    firstArg = _.first options._args
    if _.isEmpty firstArg
      console.error @usage parser.help({includeEnv: true})
      console.error colors.red 'Missing required parameter: <json-array>'
      process.exit 1

    try
      items = JSON.parse firstArg
    catch e
      console.error @usage parser.help({includeEnv: true})
      console.error colors.red "<json-array> contained invalid JSON: \"#{e.message}\""
      process.exit 1

    unless _.isArray items
      console.error @usage parser.help({includeEnv: true})
      console.error colors.red "<json-array> must be an array"
      process.exit 1

    return {items}

  run: =>
    _.each @items, (item, i) =>
      nextItem = @items[i + 1]
      return unless nextItem
      console.log diffString item, nextItem

    process.exit 0

  die: (error) =>
    return process.exit(0) unless error?
    console.error 'ERROR'
    console.error error.stack
    process.exit 1

  usage: (optionsStr) =>
    """
      usage: spot-the-difference [OPTIONS] <json-array>

      about:
        iterates over the array, printing the difference at each step

      options:
      #{optionsStr}
    """

module.exports = Command
