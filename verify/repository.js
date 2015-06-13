var exec = require('child_process').exec
var fs = require('fs')

var helper = require('../verify/helpers.js')
var userData = require('../data.json')

var addtoList = helper.addtoList
var markChallengeCompleted = helper.markChallengeCompleted
var writeData = helper.writeData

var currentChallenge = 'repository'

module.exports = function repositoryVerify (path) {
  // path should be a directory
  if (!fs.lstatSync(path).isDirectory()) return addtoList("Path is not a directory", false)
  exec('git status', {cwd: path}, function(err, stdout, stdrr) {
    // if (err) {
    //   console.log(err)
    //   return addtoList(err.message, false)
    // }
    // can't return on error since git's 'fatal' not a repo is an error
    // potentially read file, look for '.git' directory
    var status = stdout.trim()
    if (status.match("On branch")) {
      addtoList("This is a Git repository!", true)
      markChallengeCompleted(currentChallenge)
      writeData(userData, currentChallenge)
    }
    else addtoList("This folder isn't being tracked by Git.", false)
  })
}
