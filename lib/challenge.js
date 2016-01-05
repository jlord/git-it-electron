//
// This file is loaded by every challenge's HTML, it listens to events on the
// verify button and provides the file-chooser dialog when the challenge needs.
//

var selectDirBtn = document.getElementById('select-directory')

if (selectDirBtn) {
  var ipc = require('electron').ipcRenderer

  selectDirBtn.addEventListener('click', function clickedDir (event) {
    ipc.send('open-file-dialog')
  })

  ipc.on('selected-directory', function (event, path) {
    document.getElementById('path-required-warning').classList.remove('show')
    document.getElementById('directory-path').innerText = path[0]
  })
}

// Handle verify challenge click
document.getElementById('verify-challenge').addEventListener('click', function clicked (event) {
  var currentChallenge = window.currentChallenge
  var verifyChallenge = require('../lib/verify/' + currentChallenge + '.js')

  // If a directory is needed
  if (selectDirBtn) {
    var path = document.getElementById('directory-path').innerText

    if (path === '') {
      document.getElementById('path-required-warning').classList.add('show')
    } else {
      document.getElementById('verify-list').innerHTML = ''
      verifyChallenge(path)
    }
  } else {
    document.getElementById('verify-list').innerHTML = ''
    verifyChallenge()
  }
})
