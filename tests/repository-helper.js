var temp = require('temp').track()
var fs = require('fs-extra')
var path = require('path')

function extractFixture (fixtureName) {
  var fullPath = path.join(__dirname, 'fixtures', fixtureName)
  // TODO: fail at this point if the path does not exist
  var folder = temp.mkdirSync(fixtureName)
  fs.copySync(fullPath, folder)
  // rename the .git directory that we version controlled, so we can test it
  var source = path.join(folder, '_git')
  var destination = path.join(folder, '.git')
  fs.renameSync(source, destination)
  return folder
}

function createEmptyFolder (folderName) {
  var folder = temp.mkdirSync(folderName)
  return folder
}

module.exports.extractFixture = extractFixture
module.exports.createEmptyFolder = createEmptyFolder
