var exec = require('child_process').exec
var path = require('path')
var os = require('os')

var winGit = path.join(__dirname, '../assets/PortableGit/bin/git.exe  ')

module.exports = function spawnGit(command, options, callback) {
  if (typeof options === 'function') {
    callback = options
    options = null
  }
  if (os.platform() === 'win32') {
    exec('"' + winGit + '" ' + command, options, callback)
  } else {
    exec("git " + command, options, callback)
  }
}
