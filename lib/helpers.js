// var fs = require('fs')
var completed = require('../lib/challenge-completed.js')

// Set each challenge verifying process to use
// English language pack
// Potentially move this to user-data.js
process.env.LANG = 'C'

var ul = document.getElementById('verify-list')

var addtoList = function (message, status) {
  var li = document.createElement('li')
  var newContent = document.createTextNode(message)
  li.appendChild(newContent)
  if (status) {
    li.classList.add('verify-pass')
  } else li.classList.add('verify-fail')
  ul.appendChild(li)
  // potentially do this with domify and push
  // into an array and add to dom once
}

var markChallengeCompleted = function (challenge) {
  document.getElementById('challenge-completed').style.display = 'inherit'
  completed.enableClearStatus(challenge)
}

module.exports.markChallengeCompleted = markChallengeCompleted
module.exports.addtoList = addtoList
