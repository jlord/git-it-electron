var currentChallenge = document.querySelector('.challenge-item.current')

// Selecting the current locale
var selector = document.getElementById('lang-select')
selector.value = getCurrentLocale()

selector.addEventListener('change', function (event) {
  // Go to page in the locale specified
  var url
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
  if (currentChallenge) {
    regexp = /challenges(-\w+)\//
  } else {
    regexp = /index(-\w+).html/
  }
  return location.href.match(regexp) ? location.href.match(regexp)[1].substr(1) : ''
}

// Setup GA
(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','http://www.google-analytics.com/analytics.js','ga')

ga('create', 'UA-52690821-1', 'auto')
ga('send', 'pageview')
