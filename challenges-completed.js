var ipc = require('ipc')
var fs = require('fs')

var userData

document.addEventListener('DOMContentLoaded', function (event) {
  ipc.send('getUserDataPath')

  ipc.on('haveUserDataPath', function (path) {
    updateIndex('./data.json')
  })

  ipc.on('confirm-clear-response', function (response) {
    if (response === 1) return
    else clearAllChallenges()
  })

  var clearAllButton = document.getElementById('clear-all-challenges')

  clearAllButton.addEventListener('click', function (event) {
    ipc.send('confirm-clear')
  })

  function clearAllChallenges () {
    for (var chal in userData) {
      if (userData[chal].completed) {
        userData[chal].completed = false
        var completedElement = '#' + chal + ' .completed-challenge-list'
        document.querySelector(completedElement).remove()
      }
    }
    fs.writeFile('./data.json', JSON.stringify(userData, null, ' '), function (err) {
      if (err) return console.log(err)
    })
  }

  function updateIndex (path) {
    fs.readFile(path, function readFile (err, contents) {
      if (err) return console.log(err)
      userData = JSON.parse(contents)

      for (var chal in userData) {
        if (userData[chal].completed) {
          var currentText = document.getElementById(chal).innerHTML
          var completedText = "<span class='completed-challenge-list'>[ Completed ]</span>"
          document.getElementById(chal).innerHTML = completedText + ' ' + currentText
        }
      }
    })
  }
})
