var app = require('app')
var BrowserWindow = require('browser-window')
var crashReporter = require('crash-reporter')
var Menu = require('menu')
var ipc = require('ipc')
var dialog = require('dialog')

var darwinTemplate = require('./darwin-menu.js')
var otherTemplate = require('./other-menu.js')

var mainWindow = null
var menu = null

crashReporter.start()

app.on('window-all-closed', function appQuit () {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

app.on('ready', function appReady () {
  mainWindow = new BrowserWindow({width: 800, height: 900, title: 'Git-it'})
  mainWindow.loadUrl('file://' + __dirname + '/index.html')

  ipc.on('getUserDataPath', function (event) {
    var userData = app.getPath('userData')
    event.sender.send('haveUserDataPath', userData)
  })

  ipc.on('open-file-dialog', function (event) {
    var files = dialog.showOpenDialog({ properties: [ 'openFile', 'openDirectory' ]})
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
