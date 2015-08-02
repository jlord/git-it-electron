var ipc = require('ipc')
var fs = require('fs')

var userData = require('./lib/user-data.js')

document.addEventListener('DOMContentLoaded', function (event) {
  var data = userData.getData()
  var clearAllButton = document.getElementById('clear-all-challenges')

  updateIndex(data.contents)

  ipc.on('confirm-clear-response', function (response) {
    if (response === 1) return
    else clearAllChallenges(data)
  })

  clearAllButton.addEventListener('click', function () {
    ipc.send('confirm-clear')
  })

  function updateIndex (data) {
    for (var chal in data) {
      if (data[chal].completed) {
        var currentText = document.getElementById(chal).innerHTML
        var completedText = "<span class='completed-challenge-list'>Completed</span>"
        document.getElementById(chal).innerHTML = completedText + ' ' + currentText
      }
    }
  }
})

function clearAllChallenges (data) {
  for (var chal in data.contents) {
    if (data.contents[chal].completed) {
      data.contents[chal].completed = false
      var completedElement = '#' + chal + ' .completed-challenge-list'
      document.querySelector(completedElement).remove()
    }
  }
  fs.writeFileSync(data.path, JSON.stringify(data.contents, null, 2))
}
