"use strict";
class Main{
  constructor(){
    this.Remote = require('remote')
    this.App = this.Remote.require('app')
    this.Shell = this.Remote.require('shell')
    this.Main = this.App.gitIt // Remove it if we don't find any use of it
  }
  onLoaded(){
    let Me = this
    Array.prototype.forEach.call(document.querySelectorAll('a[href]'), function(Entry){
      let Link = Entry.getAttribute('href')
      if(Link.substr(0, 7) !== 'http://') return ;// Ignore local urls
      Entry.addEventListener('click', function(e){
        e.preventDefault()
        Me.Shell.openExternal(Link)
      })
    })
  }
}
class Progress {
  constructor(){
    let Me = this

    this.Challenges = ['get_git', 'repository', 'commit_to_it']

    this.Challenges.forEach(function(Challenge){ // Just in case we add more in the future
      Object.defineProperty(Me, Challenge, {
        get: function(){ return !!localStorage.getItem('git_it_' + Challenge) },
        set: function(value){ localStorage.setItem('git_it_' + Challenge, value) }
      })
    })
  }
  get active(){
    let Active = null
    let Me = this
    this.Challenges.forEach(function(Challenge){
      if(Active === null && !Me[Challenge]) Active = Challenge
    })
    return Active
  }
}
Progress = new Progress // I sometimes wish javascript had self-initializing
document.addEventListener('DOMContentLoaded', function(){
  ( new Main() ).onLoaded()
})