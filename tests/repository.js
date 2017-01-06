var test = require('tape')
var helper = require('./repository-helper')

var verify = require('../lib/verify/repository')

test('verifies the hello world repository', function (t) {
  t.plan(2)

  var folder = helper.extractFixture('hello-world')
  var result = verify(folder)

  var expected = 'This is a Git repository!'
  var actual = result[0].message

  t.assert(expected === actual)
  t.true(result[0].result)
})

test('fails an empty folder', function (t) {
  t.plan(2)

  var folder = helper.createEmptyFolder('blank-folder')
  var result = verify(folder)

  var expected = 'This folder is not being tracked by Git.'
  var actual = result[0].message

  t.assert(expected === actual)
  t.false(result[0].result)
})
