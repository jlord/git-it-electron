var ipc = require('ipc')
var fs = require('fs')

var getData = function () {
  var data = {}
  data.path = ipc.sendSync('getUserDataPath', null)
  // console.log(data.path)
  data.contents = JSON.parse(fs.readFileSync(data.path))
  console.log(data)
  return data
}

var updateData = function (challenge) {
  var data = getData()
  // console.log("update data", data)
  data.contents[challenge].completed = true

  fs.writeFile(data.path, JSON.stringify(data.contents, null, ' '), function (err) {
    if (err) return console.log(err)
  })
}

module.exports.getData = getData
module.exports.updateData = updateData
