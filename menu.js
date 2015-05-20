var Main = module.parent.exports
module.exports = {
  other: [
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
          click: function () { Main.browserWindow.close() }
        }
      ]
    },
    {
      label: '&View',
      submenu: [
        {
          label: '&Reload',
          accelerator: 'Ctrl+R',
          click: function () { Main.browserWindow.restart() }
        },
        {
          label: 'Toggle &Full Screen',
          accelerator: 'F11',
          click: function () { Main.browserWindow.setFullScreen(!Main.browserWindow.isFullScreen()) }
        },
        {
          label: 'Toggle &Developer Tools',
          accelerator: 'Ctrl+Shift+I',
          click: function () { Main.browserWindow.toggleDevTools() }
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
  ],
  darwin: [
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
          click: function () { Main.app.quit() }
        }
      ]
    },
    {
      label: 'Edit',
      submenu: [
        {
          label: 'Undo',
          accelerator: 'Command+Z',
          selector: 'undo:'
        },
        {
          label: 'Redo',
          accelerator: 'Shift+Command+Z',
          selector: 'redo:'
        },
        {
          type: 'separator'
        },
        {
          label: 'Cut',
          accelerator: 'Command+X',
          selector: 'cut:'
        },
        {
          label: 'Copy',
          accelerator: 'Command+C',
          selector: 'copy:'
        },
        {
          label: 'Paste',
          accelerator: 'Command+V',
          selector: 'paste:'
        },
        {
          label: 'Select All',
          accelerator: 'Command+A',
          selector: 'selectAll:'
        }
      ]
    },
    {
      label: 'View',
      submenu: [
        {
          label: 'Reload',
          accelerator: 'Command+R',
          click: function () { Main.browserWindow.restart() }
        },
        {
          label: 'Toggle Full Screen',
          accelerator: 'Ctrl+Command+F',
          click: function () { Main.browserWindow.setFullScreen(!Main.browserWindow.isFullScreen()) }
        },
        {
          label: 'Toggle Developer Tools',
          accelerator: 'Alt+Command+I',
          click: function () { Main.browserWindow.toggleDevTools() }
        }
      ]
    },
    {
      label: 'Window',
      submenu: [
        {
          label: 'Minimize',
          accelerator: 'Command+M',
          selector: 'performMiniaturize:'
        },
        {
          label: 'Close',
          accelerator: 'Command+W',
          selector: 'performClose:'
        },
        {
          type: 'separator'
        },
        {
          label: 'Bring All to Front',
          selector: 'arrangeInFront:'
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
}