module.exports = function menu (mainWindow) {
  var otherMenu = [
    {
      label: '&File',
      submenu: [
        {
          label: '&Open',
          accelerator: 'Ctrl+O'
        },
        {
          label: '&Quit',
          accelerator: 'Ctrl+Q',
          click: function () { mainWindow.close() }
        }
      ]
    },
    {
      label: '&View',
      submenu: [
        {
          label: '&Reload',
          accelerator: 'Ctrl+R',
          click: function () { mainWindow.restart() }
        },
        {
          label: 'Toggle &Full Screen',
          accelerator: 'F11',
          click: function () { mainWindow.setFullScreen(!mainWindow.isFullScreen()) }
        },
        {
          label: 'Toggle &Developer Tools',
          accelerator: 'Ctrl+Shift+I',
          click: function () { mainWindow.toggleDevTools() }
        }
      ]
    },
    {
      label: 'Help',
      submenu: [
        {
          label: 'Repository',
          click: function () { require('shell').openExternal('http://github.com/jlord/git-it-electron') }
        }
      ]
    }
  ]
  return otherMenu
}
