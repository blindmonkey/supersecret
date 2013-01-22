require('core/params.js')
require('core/events')

class ParamService extends Events
  constructor: ->
    super()
    @params = {}
    @transforms = {}

    @update getQueryParams()
    window.addEventListener 'hashchange', @updateFromHash.bind(this)

  updateFromHash: ->
    hash = window.location.hash.substr(1)
    params = getQueryParams hash
    @update params

  transform: (param, transform) ->
    @transforms[param] = transform

  update: (params) ->
    for param of params
      value = params[param]
      value = @transforms[param](value) if @transforms[param]
      if value != @params[param]
        @params[param] = value
        @fireEvent(param, value)

service = new ParamService()

exports.Params =
  watch: (param, handler)->
    service.handleEvent param, handler
    handler service.params[param]

  transform: (param, transform) ->
    service.transform param, transform

  exists: (param) ->
    return param of service.params

  get: (param) ->
    return service.params[param]
