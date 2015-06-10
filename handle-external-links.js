var shell = require('shell')

document.addEventListener('DOMContentLoaded', function (event) {
  var links = document.querySelectorAll('a[href]')

  [].forEach.call(links, function (link) {
    var url = link.getAttribute('href')
    if (url.indexOf('http:') > -1) {
      link.addEventListener('click', function (e) {
        e.preventDefault()
        shell.openExternal(url)
      })
    }
  }
})
