var fs = require('fs')
var cheerio =  require('cheerio')


module.exports = function translateLocale(fileContent, lang) {
  if (!lang) return

  // get translation data
  var translations = JSON.parse(fs.readFileSync(__dirname + '/locale-' + lang + '.json'))

  // load file into Cheerio
  var $ = cheerio.load(fileContent)

  var types = ["n", "v", "adj"]

  types.forEach(function (type) {

    $(type).each(function(i, tag) {
      var word = $(tag).text().toLowerCase()
      var translatiion = ""

      if (!translations[type][word]) {
        return console.log("Didn't find trasnlation for ", type, word)
      } else {
        translation = translations[type][word]
      }

      var span = "<span class='superscript'>" + translation + "</span>"
      $(tag).prepend(span)
    })
  })

  return ($.html())
}
