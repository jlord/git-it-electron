var fs = require('fs')
var completed = require('../challenge-completed.js')

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
  console.log("challenge marked completed")
  document.getElementById('challenge-completed').style.display = 'inherit'
  completed.clearStatus(challenge)
  // clear any verify list that exists
}

var writeData = function (userData, challenge) {
  userData[challenge].completed = true
  fs.writeFileSync('./data.json', JSON.stringify(userData, null, 2))
}

module.exports.writeData = writeData
module.exports.markChallengeCompleted = markChallengeCompleted
module.exports.addtoList = addtoList
