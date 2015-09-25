//
// This file edits the DOM and is required by the verify script of each
// challenge, located in the /verify directory.
//
// When parts of a challenge are checked it writes either pass or fail messages
// to the DOM. It also handles triggering all the DOM changes when
// a challenge is *completed* by calling `completed`.
//
// Because it is used by every challenge's verify script and all challenges
// need to be verified with the English language pack, that is set here too.
//

// Things to do when a challenge is completed
var completed = require('../lib/challenge-completed.js')

// Set each challenge verifying process to use
// English language pack
// Potentially move this to user-data.js
process.env.LANG = 'C'
var counter = 0

// Get the list of items to check
var ul = document.getElementById('verify-list')

var postResult = function (message, status) {
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
module.exports.postResult = postResult
module.exports.challengeIncomplete = challengeIncomplete
