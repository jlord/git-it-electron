//
// This file is used by ever web page to make sure all links that are not local
// are opened in the users default browser.
//

var shell = require('electron').shell

document.addEventListener('DOMContentLoaded', function (event) {
  var links = document.querySelectorAll('a[href]')
  var array = []
  array.forEach.call(links, function (link) {
    var url = link.getAttribute('href')
    if (url.indexOf('http') > -1) {
      link.addEventListener('click', function (e) {
        e.preventDefault()
        shell.openExternal(url)
      })
    }
  })
})
