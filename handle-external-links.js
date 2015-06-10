var shell = require('shell')

document.addEventListener('DOMContentLoaded', function (event) {
  var links = document.querySelectorAll('a[href]')

  for (var l in links) {
    var url = ''
    if (typeof links[l] === 'object') {
      url = links[l].getAttribute('href')
    }
    if (url.indexOf('http:') > -1) {
      var gohere = url // not sure why this had to be here
      links[l].addEventListener('click', function (e) {
        e.preventDefault()
        shell.openExternal(gohere)
      })
    }
  }
})
