//
// This file builds out the general web pages (like the about page). A simple
// static site generator. It uses `partials` and `layouts`.
//

var fs = require('fs')
var path = require('path')

var Handlebars = require('handlebars')

var input = path.join(__dirname, '../pages-content')
var pageFiles = fs.readdirSync(input)
var layout = fs.readFileSync(path.join(__dirname, '../layouts/page.hbs')).toString()
var output = path.join(__dirname, '../pages')

buildPages(pageFiles)

function buildPages (files) {
  files.forEach(function construct (file) {
    if (!file.match('html')) return
    var content = {
      header: buildHeader(file),
      footer: buildFooter(file),
      body: fs.readFileSync(path.join(input, file)).toString()
    }
    var template = Handlebars.compile(layout)
    var final = template(content)
    fs.writeFileSync(path.join(output, file), final)
  })
  console.log('Built pages!')
}

function buildFooter (file) {
  var source = fs.readFileSync(path.join(__dirname, '../partials/footer.html')).toString()
  var template = Handlebars.compile(source)
  return template
}

function buildHeader (filename) {
  var source = fs.readFileSync(path.join(__dirname, '../partials/header.html')).toString()
  var template = Handlebars.compile(source)
  return template({ pageTitle: filename.replace(/.html/, '') })
}
