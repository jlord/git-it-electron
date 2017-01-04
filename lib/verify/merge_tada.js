#!/usr/bin/env node
// @flow

var fs = require('fs')
var path = require('path')
var exec = require('../../lib/spawn-git.js')
var helper = require( '../../lib/helpers.js')
var userData = require('../../lib/user-data.js')

var addToList = helper.addToList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'merge_tada'
var counter = 0
var total = 2

// check that they performed a merge
// check there is not username named branch

module.exports = function verifyMergeTadaChallenge (path: string) {
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

    // don't need this cwd, but hacking this in to make flow happy
    exec('config user.username', { cwd: path }, function (err, stdout, stdrr) {
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
        } else {
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
