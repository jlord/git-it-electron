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
  mainWindow = new BrowserWindow({width: 800, height: 600})
  mainWindow.loadUrl('file://' + __dirname + '/index.html')

  ipc.on('open-file-dialog', function (event) {
    var files = dialog.showOpenDialog({ properties: [ 'openFile', 'openDirectory' ]})
    if (files) {
      event.sender.send('selected-directory', files)
    }
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
