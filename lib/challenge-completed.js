#!/usr/bin/env node

var fs = require('fs')

var userData = require('./user-data.js')

var data

// on click, disable the verify button
var verifyButton = document.getElementById('verify-challenge')
var directoryPathContent = document.getElementById('directory-path')
verifyButton.addEventListener('click', function () {
  // unless they didn't select a directory
  if (directoryPathContent && directoryPathContent.innerText && !directoryPathContent.innerText.match(/Please select/)) {
    disableVerifyButtons(true)
  }
})

var disableVerifyButtons = function (boolean) {
  document.getElementById('verify-challenge').disabled = boolean
  var directoryButton = document.getElementById('select-directory')
  if (directoryButton) { document.getElementById('select-directory').disabled = boolean }
}

var enableClearStatus = function (challenge) {
  disableVerifyButtons(true)
  var clearStatusButton = document.getElementById('clear-completed-challenge')
  clearStatusButton.style.display = 'inline-block'
  clearStatusButton.addEventListener('click', function clicked (event) {
    // set challenge to uncomplted and update the user's data file
    data.contents[challenge].completed = false
    fs.writeFileSync(data.path, JSON.stringify(data.contents, null, 2))
    // remove the completed status from the page and renable verify button
    document.getElementById(challenge).classList.remove('completed')
    disableVerifyButtons(false)
    removeClearStatus()

    // if there is a list of passed parts of challenge, remove it
    var element = document.getElementById('verify-list')
    if (element) {
      while (element.firstChild) {
        element.removeChild(element.firstChild)
      }
    }
  })
}

var removeClearStatus = function () {
  clearStatusButton = document.getElementById('clear-completed-challenge').style.display = 'none'
}

var completed = function (challenge) {
  document.addEventListener('DOMContentLoaded', function (event) {
    checkCompletedness(challenge)

    Object.keys(data.contents).forEach(function(key) {
      if(data.contents[key].completed) {
        document.getElementById(key).classList.add('completed')
      }
    })
  })

  function checkCompletedness (challenge) {
    data = userData.getData()
    if (data.contents[challenge].completed) {
      document.getElementById(challenge).classList.add('completed')
      var header = document.getElementsByTagName('header')[0]
      header.className += ' challenge-is-completed'
      // If completed, show clear button and disable verify button
      enableClearStatus(challenge)
      disableVerifyButtons(true)
    } else removeClearStatus()
  }
}

var challengeIncomplete = function () {
  // re-enable the verify button
  disableVerifyButtons(false)
}

module.exports.enableClearStatus = enableClearStatus
module.exports.completed = completed
module.exports.disableVerifyButtons = disableVerifyButtons
module.exports.challengeIncomplete = challengeIncomplete
