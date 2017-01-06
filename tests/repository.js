var test = require('tape')
var helper = require('./repository-helper')

var verify = require('../lib/verify/repository')

test('verifies the hello world repository', function (t) {
  var folder = helper.extractFixture('hello-world')
  verify(folder, function (result) {
    var expected = 'This is a Git repository!'
    var first = result[0]

    t.ok(first.result)
    t.equal(expected, first.message)
    t.end()
  })
})

test('fails an empty folder', function (t) {
  var folder = helper.createEmptyFolder('blank-folder')
  verify(folder, function (result) {
    var expected = 'This folder is not being tracked by Git.'
    var first = result[0]

    t.notOk(first.result)
    t.equal(expected, first.message)
    t.end()
  })
})
