var test = require('tape')
var helper = require('./repository-helper')

var verify = require('../lib/verify/repository')

test('verifies the hello world repository', function (t) {
  t.plan(1)

  var folder = helper.extractFixture('hello-world')
  var result = verify(folder)

  t.assert(result !== null)
})

test('fails an empty folder', function (t) {
  t.plan(1)

  var folder = helper.createEmptyFolder('blank-folder')
  var result = verify(folder)

  t.assert(result !== null)
})
