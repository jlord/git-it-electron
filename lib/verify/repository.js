var fs = require('fs')
var path = require('path')
var exec = require(path.join(__dirname, '../../lib/spawn-git.js'))

module.exports = function repositoryVerify (path, callback) {
  var result = [ ]

  // path should be a directory
  if (!fs.lstatSync(path).isDirectory()) {
    result.push({ message: 'Path is not a directory.', result: false })
    callback(result)
    return
  }

  exec('status', { cwd: path }, function (err, stdout, stdrr) {
    if (err) {
      result.push({ message: 'This folder is not being tracked by Git.', result: false })
      callback(result)
      return
    }

    // can't return on error since git's 'fatal' not a repo is an error
    // potentially read file, look for '.git' directory
    var status = stdout.trim()
    if (status.match('On branch')) {
      result.push({ message: 'This is a Git repository!', result: true })
      callback(result)
    } else {
      result.push({ message: "This folder isn't being tracked by Git.", result: false })
      callback(result)
    }
  })
}
