//
// This file talks to the main process by fetching the path to the user data.
// It also writes updates to the user-data file.
//

var ipc = require('electron').ipcRenderer
var fs = require('fs')

var getData = function () {
  var data = {}
  data.path = ipc.sendSync('getUserDataPath', null)
  data.contents = JSON.parse(fs.readFileSync(data.path))
  return data
}
var writeData = function (data) {
  fs.writeFile(data.path, JSON.stringify(data.contents, null, ' '), function updatedUserData (err) {
    if (err) return console.log(err)
  })
}

// this could take in a boolean on compelte status
// and be named better in re: to updating ONE challenge, not all
var updateData = function (challenge) {
  var data = getData()
  data.contents[challenge].completed = true

  writeData(data)
}
var updateCurrentDirectory = function (path) {
  var data = getData()
  data.contents.currentDirectory = path

  writeData(data)
}

module.exports.getData = getData
module.exports.updateData = updateData
module.exports.updateCurrentDirectory = updateCurrentDirectory
