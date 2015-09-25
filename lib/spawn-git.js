//
// We use this to wrap the exec call so that we can first check the operating
// system the user is using. This is because Windows will default to a bash
// that doesn't have Git on it, so we provide our own Git for Windows machines
// to use. 
//

var exec = require('child_process').exec
var path = require('path')
var os = require('os')

var winGit = path.join(__dirname, '../assets/PortableGit/bin/git.exe  ')

module.exports = function spawnGit (command, options, callback) {
  if (typeof options === 'function') {
    callback = options
    options = null
  }
  if (os.platform() === 'win32') {
    exec('"' + winGit + '" ' + command, options, callback)
  } else {
    exec('git  ' + command, options, callback)
  }
}
