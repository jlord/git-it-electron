#!/usr/bin/env node

var request = require('request')
var path = require('path')
const { exec } = require('child_process')
var git = require(path.join(__dirname, '../../lib/spawn-git.js'))
var helper = require(path.join(__dirname, '../../lib/helpers.js'))
var userData = require(path.join(__dirname, '../../lib/user-data.js'))

var user = ''

var addToList = helper.addToList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'githubbin'

var total = 4
var counter = 0

// verify they set up git config
// verify that user exists on GitHub (not case sensitve)
// compare the two to make sure cases match

module.exports = function verifyGitHubbinChallenge () {
  counter = 0

  git('config user.username', function (err, stdout, stderr) {
    if (err) {
      // TODO Catch 'Command failed: /bin/sh -c git config user.username'
      addToList('Error: ' + err.message, false)
      return helper.challengeIncomplete()
    }
    user = stdout.trim()
    if (user === '') {
      addToList('No username found.', false)
      helper.challengeIncomplete()
    } else {
      counter++
      addToList('Username added to Git config!', true)
      checkGitHub(user)
    }
  })

  function checkGitHub (user) {
    var options = {
      url: 'https://api.github.com/users/' + user,
      json: true,
      headers: { 'User-Agent': 'jlord' }
    }

    request(options, function (error, response, body) {
      if (error) {
        addToList('Error: ' + error.message, false)
        return helper.challengeIncomplete()
      }
      if (!error && response.statusCode === 200) {
        counter++
        addToList("You're on GitHub!", true)
        checkCapitals(body.login, user)
      } else if (response.statusCode === 404) {
        helper.challengeIncomplete()
        return addToList("GitHub account matching Git config\nusername wasn't found.", false)
      }
    })
  }

  function checkCapitals (githubUsername, configUsername) {
    if (configUsername.match(githubUsername)) {
      counter++
      addToList('Username same on GitHub and\nGit config!', true)
      checkAuthentication(githubUsername)
    } else {
      addToList('GitHub & Git config usernames\ndo not match.', false)
      helper.challengeIncomplete()
    }
  }

  function checkAuthentication(githubUsername) {
    exec('ssh -T git@github.com', function (err, stdout, stderr){
      // for some reason the command fails with err eventhough the command actually works...
      if (err) {
        if (err.message.includes(githubUsername)) {
          counter ++;
          addToList('SSH authentication is working.', true)
        }
        else {
          addToList('Error: SSH authentication failed. Message: ' + err.message, false)
          return helper.challengeIncomplete()
        }
      }
      if (counter >= total) {
        markChallengeCompleted(currentChallenge)
        userData.updateData(currentChallenge)
      }
    })
  }
}
