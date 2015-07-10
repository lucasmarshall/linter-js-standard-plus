fs = require 'fs'
path = require 'path'
{sync} = require 'resolve'
{exec} = require 'child_process'
{CompositeDisposable} = require 'atom'
{allowUnsafeNewFunctionAsync} = require 'loophole'

linterPath = atom.packages.getLoadedPackage('linter').path
findFile = require "#{linterPath}/lib/util"

module.exports =
  config:
    standardPackage:
      type: 'string'
      default: 'standard'
      enum: ['standard', 'semi-standard', 'uber-standard']
    useGlobalStandard:
      type: 'boolean'
      default: false
    showRuleIdInMessage:
      type: 'boolean'
      default: false
      description: 'Show the `ESlint` rule before the issue message'
    lintOnEdit:
      type: 'boolean'
      default: true
      description: 'Lint file while editing'

  activate: ->
    console.log 'activate linter-js-standard-plus'
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-js-standard-plus.standardPackage',
      (packageName) =>
        @standardPackage = packageName

    @subscriptions.add atom.config.observe 'linter-js-standard-plus.useGlobalStandard',
      (useGlobalStandard) =>
        @useGlobalStandard = useGlobalStandard
        if @useGlobalStandard then @_findGlobalNpmDir()

    @subscriptions.add atom.config.observe 'linter-js-standard-plus.showRuleIdInMessage',
      (showRuleIdInMessage) =>
        @showRuleIdInMessage = showRuleIdInMessage

    @standardPackage = atom.config.get('linter-js-standard-plus.standardPackage')
    @useGlobalStandard = atom.config.get('linter-js-standard-plus.useGlobalStandard')
    if @useGlobalStandard then @_findGlobalNpmDir()
    @showRuleIdInMessage = atom.config.get('linter-js-standard-plus.showRuleIdInMessage')

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    provider =
      grammarScopes: ['source.js', 'source.js.jsx']
      scope: 'file'
      lintOnFly: atom.config.get('linter-js-standard-plus-plus.lintOnEdit')
      lint: (TextEditor) =>
        return new Promise (resolve, reject) =>
          filePath = TextEditor.getPath()
          origPath = if filePath then path.dirname filePath else ''

          # `linter` comes from the configured `standard`
          linter = @_requireStandard origPath
          showRuleIdInMessage = @showRuleIdInMessage
          config = {}
          config.cwd = origPath

          if filePath
            try
              allowUnsafeNewFunctionAsync (callback) ->
                linter.lintText TextEditor.getText(), config, (error, result) ->
                  if error
                    console.warn '[linter-js-standard-plus] error while linting file'
                    console.warn error.message
                    console.warn error.stack

                    callback()
                    return resolve([
                      {
                        type: 'error'
                        text: 'error while linting file, open console for more information'
                        file: filePath
                        range: [[0, 0], [0, 0]]
                      }
                    ])
                  results = result.results[0].messages.map ({message, line, severity, column, ruleId}) ->
                    # Calculate range to make the error whole line
                    # without the indentation at begining of line
                    indentLevel = TextEditor.indentationForBufferRow line - 1
                    startCol = column ? (TextEditor.getTabLength() * indentLevel)
                    endCol = TextEditor.getBuffer().lineLengthForRow line - 1
                    range = [[line - 1, startCol], [line - 1, endCol]]

                    if showRuleIdInMessage
                      {
                        type: if severity is 1 then 'warning' else 'error'
                        html: '<span class="badge badge-flexible">' + ruleId + '</span> ' + message
                        filePath: filePath
                        range: range
                      }
                    else
                      {
                        type: if severity is 1 then 'warning' else 'error'
                        text: message
                        filePath: filePath
                        range: range
                      }

                  callback()
                  resolve(results)

            catch error
              console.warn '[linter-js-standard-plus] error while linting file'
              console.warn error.message
              console.warn error.stack

              callback()
              resolve([
                {
                  type: 'error'
                  text: 'error while linting file, open console for more information'
                  file: filePath
                  range: [[0, 0], [0, 0]]
                }
              ])

  _requireStandard: (filePath) ->
    try
      standardPath = sync @standardPackage, {basedir: path.dirname(filePath)}
      standard = require standardPath
      return standard
    catch
      if @useGlobalStandard
        try
          standardPath = sync @standardPackage, {basedir: @npmPath}
          return require standardPath
    # Fall back to the version packaged herein
    return require @standardPackage

  _findGlobalNpmDir: ->
    exec 'npm config get prefix', (code, stdout, stderr) =>
      if not stderr
        cleanPath = stdout.replace(/[\n\r\t]/g, '')
        dir = path.join(cleanPath, 'lib', 'node_modules')
        fs.exists dir, (exists) =>
          if exists
            @npmPath = dir
