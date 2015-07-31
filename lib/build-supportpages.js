var Handlebars = require('handlebars')
var fs = require('fs')

var supportingPagesContent = fs.readDirSync('./supporting-pages')

function buildSupportingPages (files) {
  var content = {
    header: buildHeader(file),
    footer: buildFooter(file),
    body: fs.readFileSync(rawFiles + file).toString()
  }
}


function buildFooter (file) {
  var source = fs.readFileSync(__dirname + '/partials/footer.html').toString()
  var template = Handlebars.compile(source)
  return template
}

function buildHeader (filename) {
  var num = filename.split('/').pop().split('_')[0]
  var data = getPrevious(num)
  var title = makeTitleName(filename)
  var source = fs.readFileSync(__dirname + '/partials/header.html').toString()
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
