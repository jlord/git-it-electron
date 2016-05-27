//
// Renderer Process—This file is required by the index page.
// It touches the DOM by showing progress in challenge completion.
// It also handles the clear buttons and writing to user-data.
//

var fs = require('fs')

var ipc = require('electron').ipcRenderer

var userData = require('./lib/user-data.js')

document.addEventListener('DOMContentLoaded', function (event) {
  var data = userData.getData()

  // Buttons
  var clearAllButtons = document.querySelectorAll('.js-clear-all-challenges')
  var leftOffButton = document.getElementById('left-off-from')
  // Sections
  var showFirstRun = document.getElementById('show-first-run')
  var showWipRun = document.getElementById('show-wip-run')
  var showFinishedRun = document.getElementById('show-finished-run')

  updateIndex(data.contents)

  // Listen for Clear All Button Events, trigger confirmation dialog
  for (var i = 0; i < clearAllButtons.length; i++) {
    clearAllButtons[i].addEventListener('click', function () {
      ipc.send('confirm-clear')
    }, false)
  }

  ipc.on('confirm-clear-response', function (event, response) {
    if (response === 1) return
    else clearAllChallenges(data)
  })

  // Go through each challenge in user data to see which are completed
  function updateIndex (data) {
    var circles = document.querySelectorAll('.progress-circle')
    var counter = 0
    var completed = 0

    for (var chal in data) {
      if (data[chal].completed) {
        // A challenge is completed so show the WIP run HTML
        showWipRun.style.display = 'block'
        showFirstRun.style.display = 'none'
        showFinishedRun.style.display = 'none'
        // Mark the corresponding circle as completed
        circles[counter].classList.add('completed')
        // Show the button to go to next challenge
        leftOffButton.href = 'challenges/' + data[chal].next_challenge + '.html'
        completed++
        counter++
      } else {
        counter++
      }
    }

    if (completed === 0) {
      // No challenges are complete, show the first run HTML
      showFirstRun.style.display = 'block'
      showWipRun.style.display = 'none'
      showFinishedRun.style.display = 'none'
    }

    if (completed === Object.keys(data).length) {
      // All of the challenges are complete! Show the finished run HTML
      showFirstRun.style.display = 'none'
      showWipRun.style.display = 'none'
      showFinishedRun.style.display = 'block'
    }
  }

  function clearAllChallenges (data) {
    for (var chal in data.contents) {
      if (data.contents[chal].completed) {
        data.contents[chal].completed = false
      }
    }
    fs.writeFileSync(data.path, JSON.stringify(data.contents, null, 2))
    // If they clear all challenges, go back to first run HTML
    var circles = document.querySelectorAll('.progress-circle')
    Array.prototype.forEach.call(circles, function (el) {
      el.classList.remove('completed')
    })

    showFirstRun.style.display = 'block'
    showWipRun.style.display = 'none'
    showFinishedRun.style.display = 'none'
  }
})
