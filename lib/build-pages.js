//
// This file builds out the general web pages (like the about page). A simple
// static site generator. It uses `partials` and `layouts`.
//

var fs = require('fs')
var path = require('path')
var locale = require('./locale.js')
var Handlebars = require('handlebars')

var langs = locale.getAvaiableLocales()

var layout = fs.readFileSync(path.normalize(path.join(__dirname, '..', 'resources', 'layouts', 'page.hbs'))).toString()
var input = ''
var output = ''

for (var lang in langs) {
  input = path.join(locale.getLocaleResourcesPath(langs[ lang ]), 'pages')
  output = path.join(locale.getLocaleBuiltPath(langs[ lang ]), 'pages')

  // If folder not exist, create it
  try {
    fs.accessSync(output)
  } catch (e) {
    fs.mkdirSync(output)
  }
  var pageFiles = fs.readdirSync(input)
  buildPages(pageFiles, langs[ lang ])
}

function buildPages (files, lang) {
  files.forEach(function construct (file) {
    if (!file.match('html')) return
    var final = ''
    if (file === 'index.html') {
      final = buildIndex(file, lang)
    } else {
      var content = {
        header: buildHeader(file, lang),
        footer: buildFooter(file, lang),
        body: fs.readFileSync(path.join(input, file)).toString()
      }
      var template = Handlebars.compile(layout)
      final = template(content)
    }
    fs.writeFileSync(path.join(output, file), final)
  })
  console.log('Built ' + lang + ' pages!')
}

function buildFooter (filename, lang) {
  var source = fs.readFileSync(getPartial('footer', lang)).toString()
  var template = Handlebars.compile(source)
  return template()
}

function buildHeader (filename, lang) {
  var source = fs.readFileSync(getPartial('header', lang)).toString()
  var template = Handlebars.compile(source)
  var contents = {
    pageTitle: filename.replace(/.html/, ''),
    localemenu: new Handlebars.SafeString(locale.getLocaleMenu(lang)),
    lang: lang
  }
  return template(contents)
}

function buildIndex (file, lang) {
  var source = fs.readFileSync(path.join(input, file)).toString()
  var template = Handlebars.compile(source)
  var content = {
    localemenu: new Handlebars.SafeString(locale.getLocaleMenu(lang))
  }
  return template(content)
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
