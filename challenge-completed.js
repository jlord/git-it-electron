#!/usr/bin/env node

var ipc = require('ipc')
var fs = require('fs')

var userData

var disableVerifyButtons = function (boolean) {
  document.getElementById('verify-challenge').disabled = boolean
  var directoryButton = document.getElementById('select-directory')
  if (directoryButton) { document.getElementById('select-directory').disabled = boolean }
}

var clearStatus = function (challenge) {
  var clearStatusButton = document.getElementById('clear-completed-challenge')
  clearStatusButton.addEventListener('click', function clicked (event) {
    userData[challenge].completed = false
    fs.writeFileSync('./data.json', JSON.stringify(userData, null, 2))
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
    ipc.send('getUserDataPath')

    ipc.on('haveUserDataPath', function (path) {
      var tempPath = './data.json'
      fs.readFile(tempPath, function (err, contents) { checkCompletedness(err, contents) })
    })
  })

  function checkCompletedness (err, contents) {
    if (err) return console.log(err)
    userData = JSON.parse(contents)
    if (userData[challenge].completed) {
      document.getElementById('challenge-completed').style.display = 'inherit'

      clearStatus(challenge)
      disableVerifyButtons(true)
    }
  }
}

module.exports.clearStatus = clearStatus
module.exports.completed = completed
module.exports.disableVerifyButtons = disableVerifyButtons
