var app = require('app')
var BrowserWindow = require('browser-window')
var Menu = require('menu')
var ipc = require('ipc')
var dialog = require('dialog')
var fs = require('fs')
var path = require('path')

var darwinTemplate = require('./menus/darwin-menu.js')
var otherTemplate = require('./menus/other-menu.js')

var emptyData = require('./empty-data.json')

var mainWindow = null
var menu = null

var iconPath = path.join(__dirname, '/assets/git-it.png')

app.on('window-all-closed', function appQuit () {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

app.on('ready', function appReady () {
  mainWindow = new BrowserWindow({"min-width": 800, "min-height": 600, width: 900, height: 600, title: 'Git-it', icon: iconPath })
  mainWindow.loadUrl('file://' + __dirname + '/index.html')

  var userDataPath = path.join(app.getPath('userData'), 'user-data.json')

  fs.exists(userDataPath, function (exists) {
    if (!exists) {
      fs.writeFile(userDataPath, JSON.stringify(emptyData, null, ' '), function (err) {
        if (err) return console.log(err)
      })
    }
  })

  ipc.on('getUserDataPath', function (event) {
    event.returnValue = userDataPath
  })

  ipc.on('open-file-dialog', function (event) {
    var files = dialog.showOpenDialog(mainWindow, { properties: [ 'openFile', 'openDirectory' ]})
    if (files) {
      event.sender.send('selected-directory', files)
    }
  })

  ipc.on('confirm-clear', function (event) {
    var options = {
      type: 'info',
      buttons: ['Yes', 'No'],
      title: 'Confirm Clearing Statuses',
      message: 'Are you sure you want to clear the status for every challenge?'
    }
    dialog.showMessageBox(options, function cb (response) {
      event.sender.send('confirm-clear-response', response)
    })
  })

  if (process.platform === 'darwin') {
    menu = Menu.buildFromTemplate(darwinTemplate(app, mainWindow))
    Menu.setApplicationMenu(menu)
  } else {
    menu = Menu.buildFromTemplate(otherTemplate(mainWindow))
    mainWindow.setMenu(menu)
  }

  mainWindow.on('closed', function winClosed () {
    mainWindow = null
  })
})
