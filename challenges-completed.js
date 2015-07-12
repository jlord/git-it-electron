var userData = require('./user-data.js')

document.addEventListener('DOMContentLoaded', function (event) {
  var data = userData.getData()
  updateIndex(data.contents)

  ipc.on('confirm-clear-response', function (response) {
    if (response === 1) return
    else clearAllChallenges()
  })

  var clearAllButton = document.getElementById('clear-all-challenges')

  clearAllButton.addEventListener('click', function () {
    for (var chal in data) {
      if (data[chal].completed) {
        data[chal].completed = false
        var completedElement = '#' + chal + ' .completed-challenge-list'
        document.querySelector(completedElement).remove()
      }
    }
    userData.updateData(data, function (err) {
      if (err) return console.log(err)
    })
  }

  function updateIndex (data) {
    for (var chal in data) {
      if (data[chal].completed) {
        var currentText = document.getElementById(chal).innerHTML
        var completedText = "<span class='completed-challenge-list'>[ Completed ]</span>"
        document.getElementById(chal).innerHTML = completedText + ' ' + currentText
      }
    }
  }
})
