### IN PROGRESS BRAIN DUMP
_Don't make PR/Issue against yet, please_

---

## Directories & Files
- **assets** Project asses like css, fonts and images.
- **challenge-content** & **challenge-content-zhtw** Main content of the challenges to be used in generating the final full HTML for each challenge page (English and Traditional Chinese).
- **challenges** & **challenges-zhtw** Full HTML for each challenge (English and Traditional Chinese)
- **layouts** Handlebars templates for the challenges and basic pages.
- **lib** All the JavaScript files for the app.
 - **verify** The JavaScript files for each challenge that verify if the challenge is completed or not.
- **menus** The app's menu layout.
- **pages** Full HTML of non-challenge pages.
- **pages-content** Main content of non-challenge pages to be used with a template to generate full HTML.
- **partials** HTML bits that are shared between either challenges or non-challenges pages, to be used in order to generate full HTML for pages.
- **tests** App's test files.
- **empty-data.json** The starter file that is duplicated and stored on the user's computer with their challenge completed statuses as they go through the lessons.
- **index.html** & **index-zhtw.html** The first page to load for the app (English and Traditional Chinese).
- **main.js** App's main process file which spins up the browser view for the pages.
- **package.json** App's details and dependencies.

### Relationships
Files and directories grouped by their relationship in the app. Electron apps have a main process, which controls the lifecycle of the app, and the browser process, which is each HTML page that is spun up by the main process.

**Main Process: Application Code**
`main.js` controls the life of the app (start, quit) and the browser windows that make up the main app experience (what HTML files to show and what size). It is the app's **main process**. The `lib` and `lib/verify` directories contain all the code that the browser views, the app's **browser process**, use. Some of these communicate with the main process by sending and receiving messages.

**Browser Process: Pages & Assets**
The pages that the app displays are HTML, just like a website. The `assests` directory contains the CSS, images and fonts used in each view. Each page starts with it's main content (`pages`, `challenge-content-zhtw`, `challenge-content`) and drops that into a template (`layouts`) along with the shared HTML elements (`partials`) like headers and footers.

**Browser Process: Scripts**
The `lib` directory contains scripts that each page uses. Inside of `lib/verify` are scripts for each challenge that tell it how to verify that challenge. The scripts `helpers.js` and `user-data.js` are shared between scripts, instructions below on [how these are used]().

**Templating**
There are scripts, templates and partials involved with generating the HTML pages. The main content for the challenges and non-challenge pages are within `challenge-content`, `challenge-content-zhtw` and `pages-content`. The directory `layouts` contains the templates, `partials` the partials that are combined with the main content files according to the template. The scripts `lib/build-page.js` and `lib/build-challenges.js` put it all in motion to generate the final HTML output which is placed in `pages`, `challenges` and `challenges-zhtw`. You can run these scripts from the command line, [instructions are below]().



---




Each view is a separate process. Each challenge shares some helper functions (helpers.js) that update the DOM in the browser process according to challenge has a script for running its verify code.

TODO—Better organize all js files, verifies? touches DOM? touches main process?

## User Data API
#### `lib/user-data.js`

The file `lib/user-data.js` contains methods for reading and writing the file stored on the user's system with their challenge completion status. It uses `ipc` to find out the user's data file location and write to it (a JSON file). It does not interact with the DOM/browser view.

```js
var userData = require('.lib/user-data.js')

// getData()
// This returns an object containing the path to where the user's data lives on the user's computer and to the raw data itself.
// * data.path
// * data.contents
var data = getData()

// updateData(challenge)
// * challenge is a string
// * asynchronous method
// This saves (using `getData() to find out the location) a challenge's completed status as `true`. The `challenge` string is the challenge name, lowercase and with underscores for spaces (matching the challenge name in the user-data.json file).
userData.updateData(currentChallenge)

```


### getData
module.exports.updateData = updateData
