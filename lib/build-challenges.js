//
// This file builds out the challenge web pages. A simple static site
// generator. It uses `partials` and `layouts`.
//

var fs = require('fs')
var path = require('path')
var glob = require('glob')
var Handlebars = require('handlebars')
var locale = require('./locale.js')
var translateLocale = require('./translate-locale.js')

var layout = fs.readFileSync(path.normalize(path.join(__dirname, '../resources/layouts/challenge.hbs'))).toString()
var files = []

// Take in a language type if any
var langs = locale.getAvaiableLocales()
var input = ''
var output = ''

// If built not exist, create one
try {
  fs.accessSync(path.join(locale.getLocaleBuiltPath(langs[ 0 ]), '..'))
} catch (e) {
  fs.mkdirSync(path.join(locale.getLocaleBuiltPath(langs[ 0 ]), '..'))
}

for (var lang in langs) {
  // If locale folder not exist, create one.
  try {
    fs.accessSync(locale.getLocaleBuiltPath(langs[ lang ]))
  } catch (e) {
    fs.mkdirSync(locale.getLocaleBuiltPath(langs[ lang ]))
  }
  input = path.join(locale.getLocaleResourcesPath(langs[ lang ]), 'challenges')
  output = path.join(locale.getLocaleBuiltPath(langs[ lang ]), 'challenges')
  try {
    fs.accessSync(output)
  } catch (e) {
    fs.mkdirSync(output)
  }
  // I can probably use glob better to avoid
  // finding the right files within the files
  files = glob.sync('*.html', { cwd: input })
  buildChallenges(files, langs[ lang ])
}

function buildChallenges (files, lang) {
  files.forEach(function (file) {
    // shouldn't have to do this if my
    // mapping were correct
    if (!file || !lang) return

    // if language, run the noun and verb
    // translations

    var content = {
      header: buildHeader(file, lang),
      sidebar: buildSidebar(file, lang),
      footer: buildFooter(file, lang),
      body: buildBody(file, lang)
    }

    if (lang && lang !== 'en-US') {
      content.body = translateLocale(content.body, lang)
    }

    content.shortname = makeShortname(file).replace('.', '')
    var template = Handlebars.compile(layout)
    var final = template(content)
    fs.writeFileSync(path.join(output, content.shortname + '.html'), final)
  })
  // hard coded right now because, reasons
  console.log('Built ' + lang + ' challenges!')
}

function makeShortname (filename) {
  // BEFORE guide/challenge-content/10_merge_tada.html
  // AFTER  merge_tada
  return filename.split('/').pop().split('_')
    .slice(1).join('_').replace('html', '')
}

function makeTitleName (filename, lang) {
  var short = makeShortname(filename).split('_').join(' ').replace('.', '')
  return grammarize(short, lang)
}

function makeTitle (title, lang) {
  var short = title.split('_').join(' ').replace('.', '')
  return grammarize(short, lang)
}

function buildHeader (filename, lang) {
  var num = filename.split('/').pop().split('_')[ 0 ]
  var data = getPrevious(num, lang)
  var title = makeTitleName(filename)
  var source = fs.readFileSync(getPartial('chal-header', lang)).toString().trim()
  var template = Handlebars.compile(source)
  var content = {
    challengetitle: title,
    challengenumber: num,
    localemenu: new Handlebars.SafeString(locale.getLocaleMenu(lang)),
    lang: lang,
    preurl: data.preurl,
    nexturl: data.nexturl
  }
  return template(content)
}

function buildSidebar (filename, lang) {
  var currentTitle = makeTitleName(filename)
  var challenges = Object.keys(require('../empty-data.json')).map(function (title) {
    var currentChallenge = currentTitle === makeTitle(title)
    return [ title, makeTitle(title), currentChallenge ]
  })
  var num = filename.split('/').pop().split('_')[ 0 ]
  var data = getPrevious(num, lang)
  var source = fs.readFileSync(getPartial('chal-sidebar', lang)).toString().trim()
  var template = Handlebars.compile(source)
  var content = {
    challenges: challenges,
    challengetitle: currentTitle,
    challengenumber: num,
    lang: lang,
    preurl: data.preurl,
    nexturl: data.nexturl
  }
  return template(content)
}

function grammarize (name, lang) {
  var correct = name
  var wrongWords = [ 'arent', 'githubbin', 'its' ]
  var rightWords = [ "aren't", 'GitHubbin', "it's" ]

  wrongWords.forEach(function (word, i) {
    if (name.match(word)) {
      correct = name.replace(word, rightWords[ i ])
    }
  })
  return correct
}

function buildFooter (file, lang) {
  var num = file.split('/').pop().split('_')[ 0 ]
  var data = getPrevious(num, lang)
  var source = fs.readFileSync(getPartial('chal-footer', lang)).toString().trim()
  data.lang = lang
  var template = Handlebars.compile(source)
  return template(data)
}

function buildBody (file, lang) {
  var source = fs.readFileSync(path.join(input, file)).toString()
  var template = Handlebars.compile(source)

  var content = {
    verify_button: fs.readFileSync(getPartial('verify-button', lang)).toString().trim(),
    verify_directory_button: fs.readFileSync(getPartial('verify-directory-button', lang)).toString().trim()
  }

  return template(content)
}

function getPrevious (num, lang) {
  var pre = parseInt(num, 10) - 1
  var next = parseInt(num, 10) + 1
  var preurl = ''
  var prename = ''
  var nexturl = ''
  var nextname = ''
  files.forEach(function (file) {
    var regexPre = '(^|[^0-9])' + pre + '([^0-9]|$)'
    var regexNext = '(^|[^0-9])' + next + '([^0-9]|$)'
    if (pre === 0) {
      prename = 'All Challenges'
      preurl = path.join('../', 'pages', 'index.html')
    } else if (file.match(regexPre)) {
      prename = makeTitleName(file, lang)
      var getridof = pre + '_'
      preurl = file.replace(getridof, '')
    }
    if (next === 12) {
      nextname = 'Done!'
      nexturl = path.join('../', 'pages', 'index.html')
    } else if (file.match(regexNext)) {
      nextname = makeTitleName(file, lang)
      getridof = next + '_'
      nexturl = file.replace(getridof, '')
    }
  })
  return {
    prename: prename, preurl: preurl,
    nextname: nextname, nexturl: nexturl
  }
}

function getPartial (filename, lang) {
  try {
    var pos = path.join(locale.getLocaleResourcesPath(lang), 'partials/' + filename + '.html')
    fs.statSync(pos)
    return pos
  } catch (e) {
    return path.join(locale.getLocaleResourcesPath(locale.getFallbackLocale()), 'partials/' + filename + '.html')
  }
}
