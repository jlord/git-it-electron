var locale = require('../lib/locale.js')
module.exports = function menu (app, mainWindow) {
  var darwinMenu = [
    {
      label: 'Git-it',
      submenu: [
        {
          label: 'About Git-it',
          selector: 'orderFrontStandardAboutPanel:'
        },
        {
          type: 'separator'
        },
        {
          label: 'Services',
          submenu: []
        },
        {
          type: 'separator'
        },
        {
          label: 'Hide Git-it',
          accelerator: 'Command+H',
          selector: 'hide:'
        },
        {
          label: 'Hide Others',
          accelerator: 'Command+Shift+H',
          selector: 'hideOtherApplications:'
        },
        {
          label: 'Show All',
          selector: 'unhideAllApplications:'
        },
        {
          type: 'separator'
        },
        {
          label: 'Quit',
          accelerator: 'Command+Q',
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
            if (focusedWindow) {
              focusedWindow.reload()
            }
          }
        },
        {
          label: 'Full Screen',
          accelerator: 'Ctrl+Command+F',
          click: function (item, focusedWindow) {
            if (focusedWindow) {
              focusedWindow.setFullScreen(!focusedWindow.isFullScreen())
            }
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
          label: 'Home',
          click: function (item, focusedWindow) {
            if (focusedWindow) {
              var path = require('path').join(locale.getLocaleBuiltPath(locale.getCurrentLocale(focusedWindow)), 'pages', 'index.html')
              focusedWindow.loadURL('file://' + path)
            }
          }
        },
        {
          label: 'Dictionary',
          click: function (item, focusedWindow) {
            if (focusedWindow) {
              var path = require('path').join(locale.getLocaleBuiltPath(locale.getCurrentLocale(focusedWindow)), 'pages', 'dictionary.html')
              focusedWindow.loadURL('file://' + path)
            }
          }
        },
        {
          label: 'Resources',
          click: function (item, focusedWindow) {
            if (focusedWindow) {
              var path = require('path').join(locale.getLocaleBuiltPath(locale.getCurrentLocale(focusedWindow)), 'pages', 'resources.html')
              focusedWindow.loadURL('file://' + path)
            }
          }
        }
      ]
    },
    {
      label: 'Help',
      submenu: [
        {
          label: 'Repository',
          click: function () {
            require('electron').shell.openExternal('http://github.com/jlord/git-it-electron')
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
              var path = require('path').join(locale.getLocaleBuiltPath(locale.getCurrentLocale(focusedWindow)), 'pages', 'about.html')
              focusedWindow.loadURL('file://' + path)
            }
          }
        }
      ]
    }
  ]
  return darwinMenu
}
