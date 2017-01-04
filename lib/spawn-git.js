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

type ErrorHandler = (error: ?Error, stdout: string | Buffer, stderr: string | Buffer) => void
type MinimalExecOptions = child_process$execOpts | child_process$execCallback

module.exports = function spawnGit (command: string, options: MinimalExecOptions, callback: ErrorHandler) {
  if (os.platform() === 'win32') {
    exec('"' + winGit + '" ' + command, options, callback)
  } else {
    exec('git ' + command, options, callback)
  }
}
