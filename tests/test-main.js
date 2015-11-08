var Application = require('spectron').Application
var test = require('tape')

// pass the path to the built application from the command line
var path = process.argv[2]

function setup() {
    app = new Application({
        path: path
    })
    return app.start()
}

function teardown() {
    if (app && app.isRunning()) {
        app.stop()
    }
}
function wrapper(description, fn) {
    test(description, function(t) {
        setup()
            .then(function() {
                return fn(t)
            })
            .then(function() {
                return teardown()
            })

    })
}
wrapper('upon application launch', function(t) {
    app.client.getWindowCount().then(function(count) {
        t.equal(count, 1, 'client window count should equal 1')
    })
    app.client.isWindowMinimized().then(function(truth) {
        t.false(truth, 'client window should not be minimized')
    })
    app.client.isWindowDevToolsOpened().then(function(truth) {
        t.false(truth, 'client window\'s dev tools should not be opened')
    })
    app.client.isWindowVisible().then(function(truth) {
        t.true(truth, 'client window should be visible')
    })
    app.client.isWindowFocused().then(function(truth) {
        t.true(truth, 'client window should be in focus')
    })
    app.client.getWindowDimensions().then(function(dimensions) {
        t.equal(dimensions.height, 600, 'client window height should equal 600')
    })
    app.client.getWindowDimensions().then(function(dimensions) {
        t.equal(dimensions.width, 900, 'client window width should equal 900')
    })
    // getWindowHeight and getWindowWidth currently fail with Tape
    // Use ^ instead of getWindowDimensions when issue is resolved
    //this.app.client.getWindowHeight().then(function(height) {
    //    t.equal(height, 600)
    //})
    t.end()
})