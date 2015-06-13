#!/usr/bin/env node

var exec = require('child_process').exec
var fs = require('fs')

var helper = require('../verify/helpers.js')
var userData = require('../data.json')

var addtoList = helper.addtoList
var markChallengeCompleted = helper.markChallengeCompleted
var writeData = helper.writeData

var currentChallenge = 'merge_tada'
var counter = 0
var total = 2

// check that they performed a merge
// check there is not username named branch

module.exports = function verifyMergeTadaChallenge (path) {
  if (!fs.lstatSync(path).isDirectory()) return addtoList('Path is not a directory', false)

  exec('git reflog -10', {cwd: path}, function (err, stdout, stdrr) {
    if (err) addtoList('Error: ' + err.message, false)
    var ref = stdout.trim()
    var user = ''

    if (ref.match('merge')) {
      counter++
      addtoList('Branch has been merged!', true)
    } else addtoList('No merge in the history.', false)

    exec('git config user.username', function (err, stdout, stdrr) {
      if (err) addtoList('Error: ' + err.message, false)
      user = stdout.trim()

      exec('git branch', {cwd: path}, function (err, stdout, stdrr) {
        if (err) addtoList('Error: ' + err.message, false)

        var branches = stdout.trim()
        var branchName = 'add-' + user

        if (branches.match(branchName)) addtoList('Uh oh, branch is still there.', false)
        else {
          counter++
          addtoList('Branch deleted!', true)
          if (counter === total) {
            counter = 0
            markChallengeCompleted(currentChallenge)
            writeData(userData, currentChallenge)
          }
        }
      })
    })
  })
}
