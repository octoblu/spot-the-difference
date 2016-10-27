colors       = require 'colors/safe'
dashdash     = require 'dashdash'
fs           = require 'fs'
_            = require 'lodash'
{diffString} = require 'json-diff'

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

  parseOptions: (callback) =>
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
      @readItemsFromStdIn (error, items) =>
        @printUsageAndErrorAndDie parser.help({includeEnv: true}), error if error?
        return callback null, {items}
    else
      @readItemsFromFile firstArg, (error, items) =>
        @printUsageAndErrorAndDie parser.help({includeEnv: true}), error if error?
        return callback null, {items}

  run: =>
    @parseOptions (error, options) =>
      return @die error if error?

      {items} = options

      outputStrings = _.map items, (item, i) =>
        nextItem = items[i + 1]
        return unless nextItem
        str = diffString item, nextItem
        return ' no difference \n' if str == ' undefined\n'
        return str

      console.log _.join(_.compact(outputStrings), "\n========================================================\n\n")

      process.exit 0

  die: (error) =>
    return process.exit(0) unless error?
    console.error 'ERROR'
    console.error error.stack
    process.exit 1

  parseItems: (itemsStr, callback) =>
    try
      items = JSON.parse itemsStr
    catch e
      return callback new Error "Invalid JSON: \"#{e.message}\""

    unless _.isArray items
      return callback new Error "JSON must be an array"

    return callback null, items


  printUsageAndErrorAndDie: (optionsStr, error) =>
    console.error @usage optionsStr
    console.error colors.red error.message
    process.exit 1

  readItemsFromFile: (filename, callback) =>
    fs.readFile filename, 'utf8', (error, itemsStr) =>
      return callback error if error?
      @parseItems itemsStr, callback

  readItemsFromStdIn: (callback) =>
    callback = _.once callback

    return callback null, '' if process.stdin.isTTY

    data = ''
    process.stdin.setEncoding('utf8')
    process.stdin.on 'readable', => data += chunk while chunk = process.stdin.read()
    process.stdin.on 'error', (error) => callback error
    process.stdin.on 'end', => @parseItems data, callback

  usage: (optionsStr) =>
    """
      usage: spot-the-difference [OPTIONS] <path/to/json-array.json>

      options:
      #{optionsStr}
    """

module.exports = Command
