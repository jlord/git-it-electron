"use strict";

var helpers = require('./helpers.js')
module.exports = function verifyGetGitChallenge(){
  helpers.execute('git config user.email').then(function(Output){
    if (Output.stdout.trim() === '') {
      return Promise.reject('No email found')
    }
  }).then(helpers.execute('git config user.name')).then(function(Output){
    if (Output.stdout.trim() === '') {
      return Promise.reject("No name found")
    }
  }).then(helpers.execute('git --version')).then(function(Output){
    if(!Output.stdout.trim().match('git version')){
      return Promise.reject("Found no Git installed.")
    }
  }).then(function(){
    // All Good to Go
    helpers.addToList('Email Added', true)
    helpers.addToList('Name Added', true)
    helpers.addToList('Found Git installed', true)
    helpers.markChallengeCompleted()
    Progress.get_git = true
  }).catch(function(Error){
    helpers.addToList(Error, false)
  })
}