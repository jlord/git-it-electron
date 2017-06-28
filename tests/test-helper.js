// create a git repository

var exec = require('child_process').exec
var tmpDir = ''

makeDirectory()

function makeDirectory () {

}

exec('git init', {cwd: tmpDir}, function initalized (err, stderr, stdout) {
  if (err) return console.log(err)
})
