var fs = require('fs')

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

var markChallengeCompleted = function () {
  var challengeBody = document.getElementById('challenge-body')
  var challengeDesc = document.getElementById('challenge-desc')
  var div = document.createElement('h2')
  var newContent = document.createTextNode('COMPLETED!')
  div.appendChild(newContent)
  div.classList.add('completed-challenge')
  challengeBody.insertBefore(div, challengeDesc)
}

var writeData = function (userData, challenge) {
  userData.get_git.completed = true
  fs.writeFileSync('./data.json', JSON.stringify(userData, null, 2))
}

module.exports.writeData = writeData
module.exports.markChallengeCompleted = markChallengeCompleted
module.exports.addtoList = addtoList
