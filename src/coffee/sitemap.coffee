app = require('./module')

capitalize = (s)->
  s && s[0].toUpperCase() + s.slice(1)

buildSiteMap = (x)->
  x.href ||= "#/#{x.name}"
  x.templateUrl ||= "/views/#{x.name}.html"
  x.controller ||= "#{capitalize(x.name)}Ctrl"
  x

module.exports = {
  main: [
    {when: '/', name: 'index', label: 'ORU/R01', href: '#/'}
    {when: '/parser', name: 'parser', label: 'Parser'}
    {when: '/tables', name: 'tables', label: 'Tables'}
  ].map(buildSiteMap)
}
