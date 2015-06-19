#!/usr/bin/env node

var exec = require('child_process').exec
var fs = require('fs')

var helper = require('../verify/helpers.js')
var userData = require('../data.json')

var addtoList = helper.addtoList
var markChallengeCompleted = helper.markChallengeCompleted
var writeData = helper.writeData

var currentChallenge = 'forks_and_clones'

// check that they've added the remote, that shows
// that they've also then forked and cloned.

module.exports = function verifyForksAndClonesChallenge (path) {
  if (!fs.lstatSync(path).isDirectory()) return addtoList('Path is not a directory', false)
  exec('git remote -v', {cwd: path}, function (err, stdout, stdrr) {
    if (err) addtoList('Error: ' + err.message, false)
    var show = stdout.trim()

    if (show.match('upstream') && show.match('github.com[\:\/]jlord/')) {
      addtoList('Upstream remote set up!', true)
      markChallengeCompleted(currentChallenge)
      writeData(userData, currentChallenge)
    } else {
      return addtoList('No upstream remote matching /jlord/Patchwork.', false)
    }
  })
}
