require('file?name=jquery.js!../../bower_components/jquery/dist/jquery.min.js')
require('../../bower_components/angular/angular.js')
require('../../bower_components/angular-animate/angular-animate.js')
require('../../bower_components/angular-cookies/angular-cookies.js')
require('../../bower_components/angular-route/angular-route.js')
require('../../bower_components/angular-sanitize/angular-sanitize.js')

module.exports = angular.module 'app', [
  'ngAnimate'
  'ngCookies'
  'ngRoute'
  'ngSanitize'
]
