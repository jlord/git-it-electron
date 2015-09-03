var exec = require('child_process').exec

var winGit = '../assets/Git-2.5.1-32-bit.exe '

module.exports = function spawnGit(command, callback) {
  if (os.platform === 'win32') {
    exec(winGit + command, function (err, stdout, stderr) {
      callback(err, stdout, stderr)
    })
  } else {
    exec("git " + command, function (err, stdout, stderr) {
      callback(err, stdout, stderr)
    })
  }
}
