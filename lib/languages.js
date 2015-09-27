//
// Touches the DOM.
// This file listens to events from the language selector and changes the
// DOM to have the language requested.
// Uses globals from chal-header.html.
//

var currentChallenge = document.querySelector('.challenge-item.current')

// Selecting the current locale
var selector = document.getElementById('lang-select')
selector.value = getCurrentLocale()

selector.addEventListener('change', function (event) {
  // Go to page in the locale specified
  var url
  var location = window.location
  if (currentChallenge) {
    var dir = 'challenges' + (selector.value ? '-' + selector.value : '') + '/'
    url = currentChallenge.href.replace(/challenges(.+)?\//, dir)
  } else {
    var index = '/index' + (selector.value ? '-' + selector.value : '') + '.html'
    url = location.href.replace(/(\/pages)?\/[\w-]+.html/, index)
  }

  location.href = url
})

// Get locale of the current page
function getCurrentLocale () {
  var regexp
  var location = window.location
  if (currentChallenge) {
    regexp = /challenges(-\w+)\//
  } else {
    regexp = /index(-\w+).html/
  }
  return location.href.match(regexp) ? location.href.match(regexp)[1].substr(1) : ''
}
