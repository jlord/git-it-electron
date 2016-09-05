module.exports = function menu (app, mainWindow) {
  var otherMenu = [
    {
      label: '&File',
      submenu: [
        // {
        //     label: '&Open',
        //     accelerator: 'Ctrl+O'
        // },
        {
          label: '&Quit',
          accelerator: 'Ctrl+Q',
          click: function () {
            app.quit()
          }
        }
      ]
    },
    {
      label: 'View',
      submenu: [
        {
          label: 'Reload',
          accelerator: 'Command+R',
          click: function (item, focusedWindow) {
            focusedWindow.reload()
          }
        },
        {
          label: 'Full Screen',
          accelerator: 'Ctrl+Command+F',
          click: function (item, focusedWindow) {
            focusedWindow.setFullScreen(!focusedWindow.isFullScreen())
          }
        },
        {
          label: 'Minimize',
          accelerator: 'Command+M',
          selector: 'performMiniaturize:'
        },
        {
          type: 'separator'
        },
        {
          label: 'Bring All to Front',
          selector: 'arrangeInFront:'
        },
        {
          type: 'separator'
        },
        {
          label: 'Toggle Developer Tools',
          accelerator: 'Alt+Command+I',
          click: function (item, focusedWindow) {
            focusedWindow.webContents.toggleDevTools()
          }
        }
      ]
    },
    {
      label: 'Window',
      submenu: [
        {
          label: 'Home(en)',
          click: function (item, focusedWindow) {
            if (focusedWindow) {
              var path = require('path').join('file://', __dirname, '..', 'built', 'en-US', 'pages', 'index.html')
              focusedWindow.loadURL(path)
            }
          }
        },
        {
          label: 'Dictionary(en)',
          click: function (item, focusedWindow) {
            if (focusedWindow) {
              var path = require('path').join('file://', __dirname, '..', 'built', 'en-US', 'pages', 'dictionary.html')
              focusedWindow.loadURL(path)
            }
          }
        },
        {
          label: 'Resources(en)',
          click: function (item, focusedWindow) {
            if (focusedWindow) {
              var path = require('path').join('file://', __dirname, '..', 'built', 'en-US', 'pages', 'resources.html')
              focusedWindow.loadURL(path)
            }
          }
        },
        {
          type: 'separator'
        }
      ]
    },
    {
      label: 'Help',
      submenu: [
        {
          label: 'Repository',
          click: function () {
            require('shell').openExternal('http://github.com/jlord/git-it-electron')
          }
        },
        {
          label: 'Open Issue',
          click: function () {
            require('electron').shell.openExternal('https://github.com/jlord/git-it-electron/issues/new')
          }
        },
        {
          label: 'About App',
          click: function (item, focusedWindow) {
            if (focusedWindow) {
              var path = require('path').join('file://', __dirname, '..', 'built', 'en-US', 'pages', 'about.html')
              focusedWindow.loadURL(path)
            }
          }
        }
      ]
    }
  ]
  return otherMenu
}
