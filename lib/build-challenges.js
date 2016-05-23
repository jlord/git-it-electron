//
// This file builds out the challenge web pages. A simple static site
// generator. It uses `partials` and `layouts`.
//

var fs = require('fs')
var path = require('path')

var glob = require('glob')
var Handlebars = require('handlebars')

var translateLocale = require('./translate-locale.js')

var layout = fs.readFileSync(path.join(__dirname, '../layouts/challenge.hbs')).toString()
var thefiles = []

// Take in a language type if any
var lang = process.argv[2]
var rawFiles = path.join(__dirname, (lang ? '../challenge-content-' + lang + '/' : '../challenge-content/'))
var builtContent = path.join(__dirname, (lang ? '../challenges-' + lang + '/' : '../challenges/'))
// I can probably use glob better to avoid
// finding the right files within the files
glob('*.html', {cwd: rawFiles}, function (err, files) {
  thefiles = files
  if (err) return console.log(err)
  buildPage(files)
})

function buildPage (files) {
  files.forEach(function (file) {
    // shouldn't have to do this if my
    // mapping were correct
    if (!file) return

    // if language, run the noun and verb
    // translations

    var content = {
      header: buildHeader(file),
      sidebar: buildSidebar(file),
      footer: buildFooter(file),
      body: buildBody(file)
    }

    if (lang) {
      content.body = translateLocale(content.body, lang)
    }

    content.shortname = makeShortname(file).replace('.', '')
    var template = Handlebars.compile(layout)
    var final = template(content)
    fs.writeFileSync(builtContent + content.shortname + '.html', final)
  })
  // hard coded right now because, reasons
  console.log('Built challenges!')
}

function makeShortname (filename) {
  // BEFORE guide/challenge-content/10_merge_tada.html
  // AFTER  merge_tada
  return filename.split('/').pop().split('_')
      .slice(1).join('_').replace('html', '')
}

function makeTitleName (filename) {
  var short = makeShortname(filename).split('_')
    .join(' ').replace('.', '')
  return grammarize(short)
}

function makeTitle (title) {
  var short = title.split('_')
    .join(' ').replace('.', '')
  return grammarize(short)
}

function buildHeader (filename) {
  var num = filename.split('/').pop().split('_')[0]
  var data = getPrevious(num)
  var title = makeTitleName(filename)
  var source = fs.readFileSync(path.join(__dirname, '../partials/chal-header.html')).toString().trim()
  var template = Handlebars.compile(source)
  var content = {
    challengetitle: title,
    challengenumber: num,
    lang: lang ? '-' + lang : '',
    preurl: data.preurl,
    nexturl: data.nexturl
  }
  return template(content)
}

function buildSidebar (filename) {
  var currentTitle = makeTitleName(filename)
  var challenges = Object.keys(require('../empty-data.json')).map(function (title) {
    var currentChallenge = currentTitle === makeTitle(title)
    return [title, makeTitle(title), currentChallenge]
  })
  var num = filename.split('/').pop().split('_')[0]
  var data = getPrevious(num)
  var source = fs.readFileSync(path.join(__dirname, '../partials/chal-sidebar.html')).toString().trim()
  var template = Handlebars.compile(source)
  var content = {
    challenges: challenges,
    challengetitle: currentTitle,
    challengenumber: num,
    lang: lang ? '-' + lang : '',
    preurl: data.preurl,
    nexturl: data.nexturl
  }
  return template(content)
}

function grammarize (name) {
  var correct = name
  var wrongWords = ['arent', 'githubbin', 'its']
  var rightWords = ["aren't", 'GitHubbin', "it's"]

  wrongWords.forEach(function (word, i) {
    if (name.match(word)) {
      correct = name.replace(word, rightWords[i])
    }
  })
  return correct
}

function buildFooter (file) {
  var num = file.split('/').pop().split('_')[0]
  var data = getPrevious(num)
  var source
  data.lang = lang ? '-' + lang : ''
  if (data.lang) {
    source = fs.readFileSync(path.join(__dirname, '../partials/chal-footer' + data.lang + '.html')).toString().trim()
  } else {
    source = fs.readFileSync(path.join(__dirname, '../partials/chal-footer.html')).toString().trim()
  }
  var template = Handlebars.compile(source)
  return template(data)
}

function buildBody (file) {
  var source = fs.readFileSync(rawFiles + file).toString()
  var template = Handlebars.compile(source)

  var content = {
    verify_button: fs.readFileSync(path.join(__dirname, '../partials/verify-button.html')).toString().trim(),
    verify_directory_button: fs.readFileSync(path.join(__dirname, '../partials/verify-directory-button.html')).toString().trim()
  }

  return template(content)
}

function getPrevious (num) {
  var pre = parseInt(num, 10) - 1
  var next = parseInt(num, 10) + 1
  var preurl = ''
  var prename = ''
  var nexturl = ''
  var nextname = ''
  thefiles.forEach(function (file) {
    var regexPre = '(^|[^0-9])' + pre + '([^0-9]|$)'
    var regexNext = '(^|[^0-9])' + next + '([^0-9]|$)'
    if (pre === 0) {
      prename = 'All Challenges'
      preurl = lang ? '../index-' + lang + '.html' : '../index.html'
    } else if (file.match(regexPre)) {
      prename = makeTitleName(file)
      var getridof = pre + '_'
      preurl = file.replace(getridof, '')
    }
    if (next === 12) {
      nextname = 'Done!'
      nexturl = lang ? '../index-' + lang + '.html' : '../index.html'
    } else if (file.match(regexNext)) {
      nextname = makeTitleName(file)
      getridof = next + '_'
      nexturl = file.replace(getridof, '')
    }
  })
  return {prename: prename, preurl: preurl,
      nextname: nextname, nexturl: nexturl}
}
