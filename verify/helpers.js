"use strict";
var ul = document.getElementById('verify-list')
let exec = require('child_process').exec
class Helpers{
  static execute(Command, Arguments){
    return new Promise(function(Resolve, Reject){
      exec(Command, Arguments, function(err, stdout, stderr){
        if(err && !(stderr && stderr.trim().length)) Reject(err)
        else Resolve({stdout: stdout, stderr: stderr}) // O YEE DESTRUCTING WHY U NO IMPLEMENT?! https://code.google.com/p/v8/issues/detail?id=811
      })
    })
  }
  static addToList(message, status) {
    var li = document.createElement('li')
    var newContent = document.createTextNode(message)
    li.appendChild(newContent)
    if (status) {
      li.classList.add('verify-pass')
    } else li.classList.add('verify-fail')
    ul.appendChild(li)
    // potentially do this with domify and push
    // into an array and add to dom once
  }
  static markChallengeCompleted(){
    var challengeBody = document.getElementById('challenge-body')
    var challengeDesc = document.getElementById('challenge-desc')
    var div = document.createElement('h2')
    var newContent = document.createTextNode('COMPLETED!')
    div.appendChild(newContent)
    div.classList.add('completed-challenge')
    // Add ID and make it so that it isn't added over and over to DOM
    challengeBody.insertBefore(div, challengeDesc)
  }
}

module.exports = Helpers