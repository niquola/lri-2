app = require('./module')
require('file?name=index.html!../index.html')
require('file?name=fhir.json!../fhir.json')
require('../less/app.less')

require('./views')

sitemap = require('./sitemap')

BASE_URL = 'http://localhost:3000/'

app.config ($routeProvider) ->
  rp = $routeProvider

  mkRoute = (acc, x)->
    acc.when(x.when, x)

  rp = sitemap.main.reduce mkRoute, rp

  rp.otherwise
    templateUrl: '/views/404.html'

activate = (name)->
  sitemap.main.forEach (x)->
    if x.name == name
      x.active = true
    else
      delete x.active

messageInfo = require('json!../../generation/result.json')

app.run ($rootScope, $location)->
  $rootScope.messageInfo = messageInfo
  $rootScope.sitemap = sitemap
  $rootScope.$on  "$routeChangeStart", (event, next, current)->
    activate(next.name)
  $rootScope.$watch 'progress', (v)->
    return unless v && v.success
    $rootScope.loading = 'Loading'
    delete $rootScope.error
    v.success (vv, status, _, req)->
       delete $rootScope.loading
     .error (vv, status, _, req)->
       console.error(arguments)
       $rootScope.error = vv || "Server error #{status} while loading:  #{req.url}"
       delete $rootScope.loading

app.filter 'icon', ()->
  (x)->
    switch x.$type
      when 'segment' then 'fa-list-ul'
      when 'field' then 'fa-circle'
      when 'group' then 'fa-folder-o'
      else ''

app.filter 'cardinality', ()->
  (x)->
    return unless x
    if x.max == "1" and x.min == "1"
      '[1]'
    else if x.max == "1" and x.min == "0"
      '[0-1]'
    else if x.max == "unbounded" and x.min == "1"
      '[1-*]'
    else if x.max == "unbounded" and x.min == "0"
      '[0-*]'
    else
      "#{x.min}-#{x.max}"
app.controller 'IndexCtrl',($scope)->
  $scope.glob = {}
  # $scope.messageInfo = messageInfo
  $scope.setActive = (item)->
    item.$open = !item.$open
    if item.$type == 'field'
      if $scope.glob.item
        $scope.glob.item.$active = false
      item.$active = true
      $scope.glob.item = item

parser = require('./parser')
_msg = require('raw!../../test/msg.hl7')

app.controller 'ParserCtrl',($scope)->
  $scope.segmentStart = (x)->
    # console.log(x.name, x.name.match(/\.1$/))
    x.name.match(/\.1$/)
  $scope.$watch 'message.text', (v)->
    return unless v
    msg = parser.parse(v, messageInfo)
    $scope.message.parsed = msg
    $scope.message.errors = parser.validate(msg)

  $scope.message = {text: _msg}

app.controller 'TablesCtrl',($scope)->
