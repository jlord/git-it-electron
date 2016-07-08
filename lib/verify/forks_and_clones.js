#!/usr/bin/env node

var exec = require('../spawn-git.js')
var fs = require('fs')

var helper = require('../helpers.js')
var userData = require('../user-data.js')

var addToList = helper.addToList

var currentChallenge = 'forks_and_clones'
var username = ''

// check that they've added the remote, that shows
// that they've also then forked and cloned.

module.exports = function verifyForksAndClonesChallenge (path) {
  if (!fs.lstatSync(path).isDirectory()) {
    addToList('Path is not a directory', false)
    return helper.challengeIncomplete()
  }

  exec('config user.username', function (err, stdout, stderr) {
    if (err) {
      addToList('Error: ' + err.message, false)
      return helper.challengeIncomplete()
    }
    username = stdout.trim()

    exec('remote -v', {cwd: path}, function (err, stdout, stdrr) {
      if (err) {
        addToList('Error: ' + err.message, false)
        return helper.challengeIncomplete()
      }
      var remotes = stdout.trim().split('\n')
      if (remotes.length != 4) {
        addToList('Not finding 2 remotes set up.', false)
        helper.challengeIncomplete()
        userData.updateData(currentChallenge)
        return
      }
      // TODO this is getting wild
      remotes.splice(1, 2)
      var incomplete = 0

      remotes.forEach(function (remote) {
        if (remote.match('origin')) {
          if (remote.match('github.com[\:\/]' + username + '/')) {
            addToList('Origin points to your fork!', true)
          } else {
            incomplete++
            addToList('Origin remote not pointing to ' + username + '/patchwork', false)

          }
        }
        if (remote.match('upstream')) {
          if (remote.match('github.com[\:\/]jlord/')) {
            addToList('Upstream remote set up!', true)
          } else {
            incomplete++
            addToList('Upstream remote not pointing to jlord/patchwork', false)
          }
        }
      })
      if (incomplete === 0) {
        userData.updateData(currentChallenge)
        helper.markChallengeCompleted(currentChallenge)
      } else helper.challengeIncomplete()
    })
  })
}
