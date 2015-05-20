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
      });
    })
  }
}
document.addEventListener('DOMContentLoaded', function(){
  ( new Main() ).onLoaded()
});