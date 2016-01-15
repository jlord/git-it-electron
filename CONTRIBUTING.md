# Contributing to Git-it (on Electron)

Contributions are more than welcome! Will fill out this doc soon.


## Packaging a release

Here's how to create a Git-it executable for Windows, OS X and Linux.

** :grey_exclamation: Requires Node.js and npm 3**

### Use npm 3

To package a release you'll need **atleast npm version 3** on your computer.
To check this:

```bash
$ npm -v
```

This is because the newer version of npm flattens the dependency tree. This is
essential for creating a version of Git-it that runs on Windows, which has
limits to file path lengths.

## Clone and install dependencies

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

**Each package is put into a folder named Git-it-Packaged-Apps which will be
just outside of your `git-it-electron` directory.** This is so that the first
one you created isn't included inside of the second one.

```bash
$ npm run pack-mac
```

This will output the contents of the application to a folder `Git-it-Packaged-Apps/Git-it-darwin-x64`
at the root of the repository.

```bash
$ npm run pack-lin
```

This will output the contents of the application to a folder `Git-it-Packaged-Apps/Git-it-linux-x64`
at the root of the repository.

```bash
$ npm run pack-win
```

A note from `electron-packager`, the module we use to package these apps:

> ## Building Windows apps from non-Windows platforms

> Building an Electron app for the Windows platform with a custom icon requires
editing the `Electron.exe` file. Currently, electron-packager uses [node-rcedit](https://github.com/atom/node-rcedit)
to accomplish this. A Windows executable is bundled in that node package and
needs to be run in order for this functionality to work, so on non-Windows
platforms, [Wine](https://www.winehq.org/) needs to be installed. On OS X, it is
installable via [Homebrew](http://brew.sh/).

This will output the contents of the application to a folder `Git-it-Packaged-Apps/Git-it-win32-ia32`
at the root of the repository.
