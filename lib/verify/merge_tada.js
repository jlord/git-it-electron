#!/usr/bin/env node

var exec = require('../spawn-git.js')
var fs = require('fs')

var helper = require('../helpers.js')
var userData = require('../user-data.js')

var addToList = helper.addToList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'merge_tada'
var counter = 0
var total = 2

// check that they performed a merge
// check there is not username named branch

module.exports = function verifyMergeTadaChallenge (path) {
  counter = 0
  if (!fs.lstatSync(path).isDirectory()) {
    addToList('Path is not a directory', false)
    return helper.challengeIncomplete()
  }

  exec('reflog -10', {cwd: path}, function (err, stdout, stdrr) {
    if (err) {
      addToList('Error: ' + err.message, false)
      return helper.challengeIncomplete()
    }
    var ref = stdout.trim()

    if (ref.match('merge')) {
      counter++
      addToList('Branch has been merged!', true)
    } else addToList('No merge in the history.', false)

    exec('config user.username', function (err, stdout, stdrr) {
      if (err) {
        addToList('Could not find username', false)
        return helper.challengeIncomplete()
      }
      var user = stdout.trim()

      exec('branch', {cwd: path}, function (err, stdout, stdrr) {
        if (err) {
          addToList('Error: ' + err.message, false)
          return helper.challengeIncomplete()
        }
        var branches = stdout.trim()
        var branchName = 'add-' + user

        if (branches.match(branchName)) {
          addToList('Uh oh, branch is still there.', false)
          helper.challengeIncomplete()
        }
        else {
          counter++
          addToList('Branch deleted!', true)
          if (counter === total) {
            markChallengeCompleted(currentChallenge)
            userData.updateData(currentChallenge)
          }
        }
      })
    })
  })
}
