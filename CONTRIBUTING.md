# Contributing to Git-it

[![js-standard-style](https://img.shields.io/badge/code%20style-standard-brightgreen.svg)](http://standardjs.com/)

Contributions are more than welcome! Checkout the [help wanted](https://github.com/jlord/git-it-electron/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted+✍%22) labels for ideas!

Code style is [standard](http://standardjs.com) and no ES6 syntax :tada: but open to relevant new methods.

For information on how the app works, see the [documentation](docs.md).

## Building Locally

If you want to build this locally you'll need [Node.js](https://nodejs.org) on your computer. Then
clone this repository, install dependencies and launch:

```bash
$ git clone https://github.com/jlord/git-it-electron
$ cd git-it-electron
$ npm install
$ npm start
```

## Packaging for OS X, Windows or Linux

Here's how to create a Git-it executable for Windows, OS X and Linux. You'll need [Node.js](https://nodejs.org) on your computer and [Wine](https://www.winehq.org/) if you're packaging for Windows from a non Windows machine (more on this below).

#### Use npm 3

To package a release you'll need **atleast npm version 3** on your computer.

To check your version of npm:

```bash
$ npm -v
```

This is because the newer version of npm flattens the dependency tree. This is
essential for creating a version of Git-it that runs on Windows, which has
limits to file path lengths.

## Clone and Install Dependencies

Clone this repository and install the dependencies:

```bash
$ git clone https://github.com/jlord/git-it-electron
$ cd git-it-electron
$ npm install
```

## Package

If you have made any changes to the code you'll need to rebuild all of the
challenges and/or pages. If you haven't, skip to the next step!

```bash
$ npm run build-all
```

### OS X, Linux, Windows

Each generated folder is put in the `/out` directory.

```bash
$ npm run pack-mac
```

This will output the contents of the application to a folder at `../out/Git-it-darwin-x64`.

```bash
$ npm run pack-lin
```

This will output the contents of the application to a folder at `../out/Git-it-linux-x64`.
```bash
$ npm run pack-win
```

A note from `electron-packager`, the module we use to package these apps:

> **Building Windows apps from non-Windows platforms**

> Building an Electron app for the Windows platform with a custom icon requires
editing the `Electron.exe` file. Currently, electron-packager uses [node-rcedit](https://github.com/atom/node-rcedit)
to accomplish this. A Windows executable is bundled in that node package and
needs to be run in order for this functionality to work, so on non-Windows
platforms, [Wine](https://www.winehq.org/) needs to be installed. On OS X, it is
installable via [Homebrew](http://brew.sh/).

This will output the contents of the application to a folder at `../out/Git-it-win32-ia32`.
