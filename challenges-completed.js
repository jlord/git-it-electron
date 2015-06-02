var ipc = require('ipc')
var updateIndex = require('./updateIndex')

document.addEventListener('DOMContentLoaded', function (event) {
  ipc.send('getUserDataPath')

  ipc.on('haveUserDataPath', function (path) {
    console.log(path)
    updateIndex('./data.json')
  })
})
