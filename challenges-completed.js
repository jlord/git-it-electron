var ipc = require('ipc')
var fs = require('fs')

var userData

document.addEventListener('DOMContentLoaded', function (event) {
  ipc.send('getUserDataPath')

  ipc.on('haveUserDataPath', function (path) {
    console.log(path)
    updateIndex('./data.json')
  })

  var clearButton = document.getElementById('clear-all-challenges')

  clearButton.addEventListener('click', function (event) {
    console.log('clear all')

    for (var chal in userData) {
      if (userData[chal].completed) {
        userData[chal].completed = false
        // var completedElement = '#' + chal + ' .completed-challenge-list'
        // need to remove the span inside of each <li>
      }
    // fs.writeFile('./data.json', JSON.stringify(userData, null, ' '), function (err) {
    //
    // })
    }
  })
})

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
