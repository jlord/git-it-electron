var ipc = require('ipc')
var fs = require('fs')

// for getting, reading and writing the user data
// aka the challenge statuses

var getPath = function (cb) {
  ipc.send('getUserDataPath')

  ipc.on('haveUserDataPath', function (userPath) {
    cb(userPath)
  })
}

var getData = function (cb) {
  getPath(function (path) {
    return fs.readFileSync(path)
  })
}

var updateData = function (data, cb) {
  var path = getPath()
  fs.writeFile(path, JSON.stringify(data, null, ' '), function (err) {
    if (err) return cb(err)
  })
}

module.exports.getPath = getPath
module.exports.getData = getData
module.exports.updateData = updateData
