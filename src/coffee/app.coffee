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
  $scope.messageInfo = messageInfo
  $scope.setActive = (item)->
    item.$open = !item.$open
    if item.$type == 'field'
      if $scope.glob.item
        $scope.glob.item.$active = false
      item.$active = true
      $scope.glob.item = item

parser = require('./parser')

app.controller 'ParserCtrl',($scope)->
  _msg = """
  MSH|^~\&|^2.16.840.1.113883.3.72.5.20^ISO|^2.16.840.1.113883.3.72.5.21^ISO||^2.16.840.1.113883.3.72.5.23^ISO|20110331160551-0700||ORU^R01^ORU_R01|NIST-LRI-TC-NG-XXX.XX|T|2.5.1|||AL|NE|||||Base Profile LRI R1^^2.16.840.1.113883.9.16^ISO~Profile NG^^2.16.840.1.113883.9.13^ISO~Profile RU^^2.16.840.1.113883.9.14^ISO
  PID|1||PATID1234^^^&2.16.840.1.113883.3.72.5.30.1&ISO^MR||JONES^WILLIAM||||||||||||||||||||||
  ORC|RE|ORD723222^^2.16.840.1.113883.3.72.5.24^ISO|R-783274^^2.16.840.1.113883.3.72.5.25^ISO|GORD874211^^2.16.840.1.113883.3.72.5.24^ISO||||||||57422^RADON^NICHOLAS^^^^^^&2.16.840.1.113883.3.72.5.30.1&ISO
  OBR|1|ORD723222^^2.16.840.1.113883.3.72.5.24^ISO|R-783274^^2.16.840.1.113883.3.72.5.25^ISO|30341-2^Erythrocyte sedimentation rate^LN|||20110331140551-0700|||||||||57422^RADON^NICHOLAS^^^^^^&2.16.840.1.113883.3.72.5.30.1&ISO||||||20110331160428-0700|||F|||10092^HAMLIN^PAFFORD
  """
  $scope.$watch 'message.text', (v)->
    return unless v
    $scope.message.parsed = parser.parse(v, messageInfo)

  $scope.message = {text: _msg}

app.controller 'TablesCtrl',($scope)->
