// @flow

//
// This file is a wrapper to the exec call used in each of the verify scripts.
// It first checks what operating system is being used and if Windows it uses
// the Portable Git rather than the system Git.
//

var exec = require('child_process').exec
var path = require('path')
var os = require('os')

var winGit = path.join(__dirname, '../assets/PortableGit/bin/git.exe')

type ErrorHandler = (error: ?Error, stdout: string, stderr: string) => void
type MinimalExecOptions = child_process$execOpts | child_process$execCallback

function getText(stdout: Buffer | string): string {
  if (Buffer.isBuffer(stdout)) {
    const text = stdout.toString()
    return text.trim()
  } else if (typeof stdout === 'string') {
    return stdout.trim()
  }

  throw new Error(`Unable to get text from type: ${typeof stdout}`)
}

module.exports = function spawnGit (command: string, options: MinimalExecOptions, callback: ErrorHandler) {
  if (os.platform() === 'win32') {
    exec('"' + winGit + '" ' + command, options, function(err, stdout, stderr) {
      const output = getText(stdout)
      const error = getText(stderr)
      callback(err, output, error)
     })
  } else {
    exec('git ' + command, options, function(err, stdout, stderr) {
      const output = getText(stdout)
      const error = getText(stderr)
      callback(err, output, error)
     })
  }
}
