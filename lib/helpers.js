//
// This file is used by every challenge's verify file and is an API for writing
// partial challenge completion messages to the DOM and setting a challenge
// as complete when all parts of a challenge have passed.
//
// It also sets the lanaguage for each challenge's verify's process's Git to
// English.
//

var completed = require('../lib/challenge-completed.js')

// Set each challenge verifying process to use
// English language pack
// Potentially move this to user-data.js
process.env.LANG = 'C'

var ul = document.getElementById('verify-list')

var addToList = function (message, status) {
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
  document.getElementById(challenge).classList.add('completed')
  completed.enableClearStatus(challenge)
}

var challengeIncomplete = function () {
  completed.challengeIncomplete()
}

module.exports.markChallengeCompleted = markChallengeCompleted
module.exports.addToList = addToList
module.exports.challengeIncomplete = challengeIncomplete
