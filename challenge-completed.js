#!/usr/bin/env node

var ipc = require('ipc')
var fs = require('fs')

module.exports = function challengeCompleted (challenge) {
  document.addEventListener('DOMContentLoaded', function (event) {
    ipc.send('getUserDataPath')

    ipc.on('haveUserDataPath', function (path) {
      var tempPath = './data.json'
      fs.readFile(tempPath, function (err, contents) { checkCompletedness(err, contents) })
    })
  })

  function checkCompletedness (err, contents) {
    if (err) return console.log(err)
    var userData = JSON.parse(contents)
    if (userData[challenge].completed) {
      document.getElementById('challenge-completed').style.display = 'inherit'
      // disable buttons
      document.getElementById('verify-challenge').setAttribute('disabled', 'true')
      var directoryButton = document.getElementById('select-directory')
      if (directoryButton) { document.getElementById('select-directory').setAttribute('disabled', 'true') }
      // TODO add a 'clear challenge status' button & menu
    }
  }
}
