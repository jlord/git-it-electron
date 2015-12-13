# Contributing to Git-it (on Electron)

Contributions are more than welcome! Will fill out this doc soon.


## Packaging a release

There are two additional packages you need to generate the packages for each
platform:

> npm install -g electron-packager # electron-packager@5.1.1
> npm install -g flatten-packages  # flatten-packages@0.1.4

Install all the necessary packages you need:

> git clean -xdf
> npm install

Then rebuild the assets for the app:

> npm run build-all

Ensure any uncommitted changes are committed before continuing.

Due to some cross-platform limitations, cross-platform packaging is limited. To
package up the OS X version (you must be in OS X):

> npm run pack-mac

This will output the contents of the application to a folder `Git-it-darwin-x64`
at the root of the repository.

To package the Windows version (you must be in Windows):

> npm run pack-win

This will output the contents of the application to a folder `Git-it-win32-ia32`
at the root of the repository.
