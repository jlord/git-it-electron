#!/usr/bin/env node

var exec = require('child_process').exec
var fs = require('fs')
var path = require('path')

var helper = require('../helpers.js')
var userData = require('../user-data.js')

var addtoList = helper.addtoList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'branches_arent_just_for_birds'
var total = 3
var counter = 0
var username = ''

// get their username
// verify branch matches username, case too.
// verify they've pushed
// check the file is in contributors directory

module.exports = function verifyBranchesChallenge (repopath) {
  counter = 0
  repopath = repopath
  if (!fs.lstatSync(repopath).isDirectory()) return addtoList('Path is not a directory', false)
  exec('git config user.username', {cwd: repopath}, function (err, stdout, stderr) {
    if (err) {
      helper.challengeIncomplete()
      return addtoList('Error: ' + err.message, false)
    }
    username = stdout.trim()

    exec('git rev-parse --abbrev-ref HEAD', {cwd: repopath}, function (err, stdout, stderr) {
      if (err) {
        addtoList('Error: ' + err.message, false)
        return helper.challengeIncomplete()
      }
      var actualBranch = stdout.trim()
      var expectedBranch = 'add-' + username
      if (actualBranch.match(expectedBranch)) {
        counter++
        addtoList('Found branch as expected!', true)
        checkPush(actualBranch)
      } else {
        addtoList('Branch name expected: ' + expectedBranch, false)
        checkPush(actualBranch)
      }
    })
  })

  function checkPush (branchname) {
    // look into this, is using reflog the best way? what about origin?
    // sometimes it seems this doesn't work
    exec('git reflog show origin/' + branchname, {cwd: repopath}, function (err, stdout, stderr) {
      if (err) {
        addtoList('Error: ' + err.message, false)
        return helper.challengeIncomplete()
      }
      if (stdout.match('update by push')) {
        counter++
        addtoList('Changes have been pushed!', true)
      } else addtoList('Changes not pushed', false)
      findFile()
    })
  }

  function findFile () {
    // see if user is already within /contributors
    if (repopath.match('contributors')) {
      check(repopath)
    } else {
      check(path.join(repopath, '/contributors/'))
    }

    function check (userspath) {
      fs.readdir(userspath, function (err, files) {
        if (err) {
          addtoList('Error: ' + err.message, false)
          return helper.challengeIncomplete()
        }
        var allFiles = files.join()
        if (allFiles.match(username)) {
          counter++
          addtoList('File in contributors folder!', true)
          if (counter === total) {
            markChallengeCompleted(currentChallenge)
            userData.updateData(currentChallenge)
          }
        } else {
          addtoList('File not in contributors folder!', false)
          helper.challengeIncomplete()
        }
      })
    }
  }
}
