//
// This file is required by the index page with the list of all challenges.
// It touches the DOM by marking which challenges are complete. It also handles
// the clear button and writing to user-data.
//

var ipc = require('electron').ipcRenderer
var fs = require('fs')

var userData = require('./lib/user-data.js')

document.addEventListener('DOMContentLoaded', function (event) {
  var data = userData.getData()
  var clearAllButton = document.getElementById('clear-all-challenges')
  var getStartedButton = document.getElementById('get-started')
  var leftOffButton = document.getElementById('left-off-from')
  var doneClearButton = document.getElementById('done-clear')

  updateIndex(data.contents)

  ipc.on('confirm-clear-response', function (event, response) {
    if (response === 1) return
    else clearAllChallenges(data)
  })

  clearAllButton.addEventListener('click', function () {
    ipc.send('confirm-clear')
  })

  function updateIndex (data) {
    var counter = 0
    for (var chal in data) {
      if (data[chal].completed) {
        // if one is completed and clear all button is disabled, show it
        // hide get started button
        if (clearAllButton.disabled) clearAllButton.disabled = false
        // if (getStartedButton.style.display === 'block') {
        //   getStartedButton.style.display = 'none'
        // }
        var currentText = document.getElementById(chal).innerHTML
        var completedText = "<span class='completed-challenge-list'>✔︎</span>"
        document.getElementById(chal).innerHTML = completedText + ' ' + currentText
        // if one is completed, hide Get Started button and show Left Off From button
        getStartedButton.style.display = 'none'
        leftOffButton.style.display = 'block'
        leftOffButton.href = 'challenges/' + data[chal].next_challenge + '.html'
      } else {
        counter++
      }
    }
    if (counter === Object.keys(data).length) {
      // no challenges are complete, don't disable/hide clear button
      // show get started button
      clearAllButton.disabled = true
      getStartedButton.style.display = 'block'
    }
    if (counter === 0) {
      // all challenges are complete, ask if they want to clear status
      getStartedButton.style.display = 'none'
      leftOffButton.style.display = 'none'
      doneClearButton.addEventListener('click', function () {
        ipc.send('confirm-clear')
      })
      doneClearButton.style.display = 'block'
    }
  }

  function clearAllChallenges (data) {
    for (var chal in data.contents) {
      if (data.contents[chal].completed) {
        data.contents[chal].completed = false
        var completedElement = '#' + chal + ' .completed-challenge-list'
        document.querySelector(completedElement).remove()
      }
    }
    fs.writeFileSync(data.path, JSON.stringify(data.contents, null, 2))
    clearAllButton.disabled = true
    getStartedButton.style.display = 'block'
    leftOffButton.style.display = 'none'
    doneClearButton.style.display = 'none'
  }
})
