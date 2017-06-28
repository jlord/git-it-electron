# Contributing to Git-it

[![js-standard-style](https://img.shields.io/badge/code%20style-standard-brightgreen.svg)](http://standardjs.com/)

Contributions are more than welcome! Checkout the [help wanted](https://github.com/jlord/git-it-electron/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted+✍%22) labels for ideas!

---

**📣 Provide a description in your Issue/Pull Request.** In your pull request please explain what the problem was (with gifs or screenshots would be fantastic!) and how your changes fix it. 

🚫 🙀 :fire: _No description provided._ :fire: 🙀 🚫

---

**Code style is [JS Standard](http://standardjs.com) and no ES6 syntax** :tada: but open to relevant new methods.

Changes to the content of the pages must be made in the `challenge-content` directory (for appropriate language). For more information on how the app works, **see the [documentation](docs.md)**.

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

If you have made any changes to the code or you just cloned this project from github,
you'll need to rebuild all of the challenges and/or pages.
If you haven't, skip to the next step!

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


## Translations to other languages
If you want to add a new language to this project, here are some step you need to do.

### Add locale code
First, edit `locale.js` and add locale code in it. You can use any editor you like.

```bash
$ vim lib/locale.js
```

In `locale.js`, there must have a variable called 'available', and add your language in it.  
For example, we have already had three languages, and wanted to add German(Germany):

```javascript
var available = {
  'en-US': 'English',
  'ja-JP': '日本語',
  'zh-TW': '中文(臺灣)',
  'de-DE': 'Deutsch'
}
```

Before colon is your language code, it must look like '\<lang\>-\<location\>'. '\<lang\>' is your language, in this case, 'de' is the language code of 'German'. '\<location\>' is your location code, in this case, 'DE' is the location code of 'Germany'. If you don't know what your language/location code, you can find it [here](http://www.lingoes.net/en/translator/langcode.htm).  

> **The language code *MUST* be all lowercase, and location code *MUST* be all uppercase.**  


If there are lots of locations using same language, you could add your language in variable 'aliases'.  App will auto-redirect to target language. For example, There are five locations using 'German' as their language (de-AT, de-CH, de-DE, de-LI and de-LU),  you can add 'de' into 'aliases' and let app using 'de-DE' for default 'de' language.

```javascript
var aliases = {
  'en': 'en-US',
  'ja': 'ja-JP',
  'zh': 'zh-TW',
  'de': 'de-DE'
}
```
> **Locale in aliases *MUST* point to a locale existed in available.**

### Translate files
All files that translator should edit is in `resources/contents`. We suggest translator using 'en-US' as original language to translate.  

```bash
cd resources/contents
cp en-US '<your-lang>-<your-location>'
```
> **Folder name in resources/contents *MUST* be the same as the locale you added in locale.js.**

### Build
Don't forget to build to generate built file.

```bash
npm run build-all
```
