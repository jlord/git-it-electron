var app = require('app')
var BrowserWindow = require('browser-window')
var crashReporter = require('crash-reporter')

crashReporter.start()

var mainWindow = null

app.on('window-all-closed', function appQuit () {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

app.on('ready', function appReady () {
  mainWindow = new BrowserWindow({width: 800, height: 600})
  mainWindow.loadUrl('file://' + __dirname + '/index.html')

  mainWindow.on('closed', function winClosed () {
    mainWindow = null
  })
})
