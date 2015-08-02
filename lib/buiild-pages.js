var Handlebars = require('handlebars')
var fs = require('fs')
var path = require('path')

var input = path.join(__dirname, '../pages-content')
var pageFiles = fs.readdirSync(input)
var layout = fs.readFileSync(path.join(__dirname, '../layouts/page.hbs')).toString()
var output = path.join(__dirname, '../pages')

buildPages(pageFiles)

function buildPages (files) {
  console.log('files', files)
  files.forEach(function construct (file) {
    if (!file.match('html')) return
    var content = {
      header: buildHeader(file),
      footer: buildFooter(file),
      body: fs.readFileSync(path.join(input, file)).toString()
    }
    var template = Handlebars.compile(layout)
    var final = template(content)
    fs.writeFile(path.join(output, file), final, function (err) {
      if (err) return console.log(err)
    })
  })
  console.log('Built pages!')
}

function buildFooter (file) {
  var source = fs.readFileSync(path.join(__dirname, '../partials/footer.html')).toString()
  var template = Handlebars.compile(source)
  return template
}

function buildHeader (filename) {
  var source = fs.readFileSync(path.join(__dirname, '../partials/head.html')).toString()
  var template = Handlebars.compile(source)
  return template
}
