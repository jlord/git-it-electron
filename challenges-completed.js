var ipc = require('ipc')
var fs = require('fs')

document.addEventListener('DOMContentLoaded', function (event) {
  ipc.send('getUserDataPath')

  ipc.on('haveUserDataPath', function (path) {
    console.log(path)
    updateIndex('./data.json')
  })
})

function updateIndex (path) {
  fs.readFile(path, function readFile (err, contents) {
    if (err) return console.log(err)
    var userData = JSON.parse(contents)

    for (var chal in userData) {
      if (userData[chal].completed) {
        var currentText = document.getElementById(chal).innerHTML
        var completedText = "<span class='compelted-challenge-list'>[ Completed ]</span>"
        document.getElementById(chal).innerHTML = completedText + ' ' + currentText
      }
    }
  })
}
