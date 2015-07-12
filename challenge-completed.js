#!/usr/bin/env node

var fs = require('fs')

var userData = require('./user-data.js')

var data

var disableVerifyButtons = function (boolean) {
  document.getElementById('verify-challenge').disabled = boolean
  var directoryButton = document.getElementById('select-directory')
  if (directoryButton) { document.getElementById('select-directory').disabled = boolean }
}

var clearStatus = function (challenge) {
  var clearStatusButton = document.getElementById('clear-completed-challenge')
  clearStatusButton.addEventListener('click', function clicked (event) {
    data[challenge].completed = false
    fs.writeFileSync('./data.json', JSON.stringify(data, null, 2))
    document.getElementById('challenge-completed').style.display = 'none'
    disableVerifyButtons(false)

    // if there is a list of passed parts of challenge, remove it
    var element = document.getElementById('verify-list')
    if (element) {
      while (element.firstChild) {
        element.removeChild(element.firstChild)
      }
    }
  })
}

var completed = function (challenge) {
  challenge = challenge
  document.addEventListener('DOMContentLoaded', function (event) {
    checkCompletedness()
  })

  function checkCompletedness () {
    var data = userData.getData()
    if (data.contents[challenge].completed) {
      document.getElementById('challenge-completed').style.display = 'inherit'

      clearStatus(challenge)
      disableVerifyButtons(true)
    }
  }
}

module.exports.clearStatus = clearStatus
module.exports.completed = completed
module.exports.disableVerifyButtons = disableVerifyButtons
