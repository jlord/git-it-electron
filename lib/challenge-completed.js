//
// This file touches the DOM and provides an API for setting the page after
// challenge has been completed by toggling the buttons that are disabled
// or enabled. It as updates user-data.
//
// It is required by each challenge's verify file.
//

var fs = require('fs')

var userData = require('./user-data.js')

var data

// on click, disable the verify button
var verifyButton = document.getElementById('verify-challenge')
var directoryPathContent = document.getElementById('directory-path')

verifyButton.addEventListener('click', function () {
  // show spinner
  document.getElementById('verify-spinner').style.display = 'inline-block'
  // unless they didn't select a directory
  if (directoryPathContent && directoryPathContent.innerText && !directoryPathContent.innerText.match(/Please select/)) {
    document.getElementById('verify-list').style.display = 'block'
    disableVerifyButtons(true)
  }
  // if there is no directory button
  if (!directoryPathContent) {
    document.getElementById('verify-list').style.display = 'block'
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
  // hide spinner
  document.getElementById('verify-spinner').style.display = 'none'
  var clearStatusButton = document.getElementById('clear-completed-challenge')
  clearStatusButton.style.display = 'inline-block'
  clearStatusButton.addEventListener('click', function clicked (event) {
    // set challenge to uncompleted and update the user's data file
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
  document.getElementById('clear-completed-challenge').style.display = 'none'
}

var completed = function (challenge) {
  document.addEventListener('DOMContentLoaded', function (event) {
    checkCompletedness(challenge)

    Object.keys(data.contents).forEach(function (key) {
      if (data.contents[key].completed) {
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
  document.getElementById('verify-spinner').style.display = 'none'
}

module.exports.enableClearStatus = enableClearStatus
module.exports.completed = completed
module.exports.disableVerifyButtons = disableVerifyButtons
module.exports.challengeIncomplete = challengeIncomplete
