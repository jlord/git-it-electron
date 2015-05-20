"use strict"; // Required to use classes in v8
var
  path = require('path'),
  app = require('app'),
  BrowserWindow = require('browser-window'),
  Menu = require('menu');

require('crash-reporter').start()

class Main{
  static init(){
    process.name = 'git-it-electron' // Useful for programs like `ps`
    app.setName('git-it-electron')
    app.on('window-all-closed', Main.windowsClosed)
    app.setPath('userData', path.join(app.getPath('appData'), app.getName()))
    app.setPath('userCache', path.join(app.getPath('cache'), app.getName()))

    Main.browserWindow = null
    Main.app = app
  }
  static onReady(){
    let appMenu = require('./menu')

    Main.browserWindow = new BrowserWindow({width: 800, height: 600})
    Main.browserWindow.loadUrl('file://' + __dirname + '/index.html')
    if(process.platform === 'darwin'){
      Menu.setApplicationMenu(Menu.buildFromTemplate(appMenu.darwin))
    } else {
      Main.browserWindow.setMenu(Menu.buildFromTemplate(appMenu.other))
    }
    Main.browserWindow.on('closed', function(){
      Main.browserWindow = null
    })
  }
  static windowsClosed(){
    if (process.platform !== 'darwin') {
      app.quit()
    }
  }
}

Main.init()
app.on('ready', Main.onReady)

module.exports = app.gitIt = Main // Creating a reference here so we can use it in other modules and on the renderer side too, in case we want