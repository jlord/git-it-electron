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
type execOpts = {
  cwd?: string;
  env?: Object;
  encoding?: string;
  shell?: string;
  timeout?: number;
  maxBuffer?: number;
  killSignal?: string;
  uid?: number;
  gid?: number;
}

function getText (stdout: Buffer | string): string {
  if (Buffer.isBuffer(stdout)) {
    const text = stdout.toString()
    return text.trim()
  } else if (typeof stdout === 'string') {
    return stdout.trim()
  }

  throw new Error(`Unable to get text from type: ${typeof stdout}`)
}

module.exports = function spawnGit (command: string, options: execOpts | ErrorHandler, callback?: ErrorHandler) {
  var opts: execOpts = (typeof options === 'function')
    ? { }
    : options

  var cb: ?ErrorHandler = (typeof options === 'object')
    ? callback
    : options

  if (os.platform() === 'win32') {
    exec('"' + winGit + '" ' + command, opts, function (err, stdout, stderr) {
      if (cb) {
        const output = getText(stdout)
        const error = getText(stderr)
        cb(err, output, error)
      }
    })
  } else {
    exec('git ' + command, opts, function (err, stdout, stderr) {
      if (cb) {
        const output = getText(stdout)
        const error = getText(stderr)
        cb(err, output, error)
      }
    })
  }
}
