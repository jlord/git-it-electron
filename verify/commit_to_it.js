var exec = require('child_process').exec
var fs = require('fs')

var helper = require('../verify/helpers.js')
var userData = require('../data.json')

var addtoList = helper.addtoList
var markChallengeCompleted = helper.markChallengeCompleted
var writeData = helper.writeData

var currentChallenge = 'commit_to_it'

// check that they've commited changes

module.exports = function commitVerify (path) {
  if (!fs.lstatSync(path).isDirectory()) return addtoList('Path is not a directory', false)
  exec('git status', {cwd: path}, function (err, stdout, stdrr) {
    if (err) return addtoList(err.message, false)
    var show = stdout.trim()

    if (show.match('Initial commit')) {
      addtoList("Hmm, can't find committed changes.", false)
    } else if (show.match('nothing to commit')) {
      addtoList('Changes have been committed!', true)
      markChallengeCompleted()
      writeData(userData, currentChallenge)
    } else {
      addtoList('Seems there are changes to commit still.', false)
    }
  })
}
