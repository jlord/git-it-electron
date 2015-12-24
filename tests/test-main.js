var Application = require('spectron').Application
var test = require('tape')

// pass the path to the built application from the command line
var path = process.argv[2]

var app = null

function setup () {
  app = new Application({
    path: path
  })
  return app.start()
}

function teardown (t) {
  if (app && app.isRunning()) {
    return app.stop().then(function () {
      t.end()
    }, function (error) {
      t.end(error)
    })
  } else {
    t.end()
  }
}
function wrapper (description, fn) {
  test(description, function (t) {
    setup()
      .then(function () {
        return fn(t)
      })
      .then(function () {
        return teardown(t)
      })

  })
}

wrapper('getWindowCount launch', function (t) {
  return app.client.getWindowCount().then(function (count) {
    t.equal(count, 1, 'client window count should equal 1')
  })
})

wrapper('isWindowMinimized test', function (t) {
  return app.client.isWindowMinimized().then(function (truth) {
    t.false(truth, 'client window should not be minimized')
  })
})

wrapper('isWindowDevToolsOpened test', function (t) {
  return app.client.isWindowDevToolsOpened().then(function (truth) {
    t.false(truth, 'client window\'s dev tools should not be opened')
  })
})

wrapper('isWindowVisible test', function (t) {
  return app.client.isWindowVisible().then(function (truth) {
    t.true(truth, 'client window should be visible')
  })
})

wrapper('isWindowFocused test', function (t) {
  return app.client.isWindowFocused().then(function (truth) {
    t.true(truth, 'client window should be in focus')
  })
})

wrapper('getWindowHeight test', function (t) {
  return app.client.getWindowHeight().then(function (height) {
    t.equal(height, 600, 'client window height should equal 600')
  })
})

wrapper('getWindowWidth test', function (t) {
  return app.client.getWindowWidth().then(function (width) {
    t.equal(width, 900, 'client window width should equal 900')
  })
})
