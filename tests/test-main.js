var Application = require('spectron').Application
var test = require('tape')

// pass the path to the built application from the command line
var path = process.argv[2]

function setup() {
    this.app = new Application({
        path: path
    })
    return this.app.start()
}

function teardown() {
    if (this.app && this.app.isRunning()) {
        this.app.stop()
    }
}
function wrapper(description, fn) {
    test(description, function(t) {
        setup()
            .then(function() {
                fn(t)
            })
            .then(function() {
                teardown()
            })
    })
}
wrapper('application launch', function(t) {
    this.app.client.getWindowCount().then(function(count) {
        t.equal(count, 1)
    })
    this.app.client.isWindowMinimized().then(function(truth) {
        t.false(truth)
    })
    this.app.client.isWindowDevToolsOpened().then(function(truth) {
        t.false(truth)
    })
    this.app.client.isWindowVisible().then(function(truth) {
        t.true(truth)
    })
    this.app.client.isWindowFocused().then(function(truth) {
        t.true(truth)
    })
    this.app.client.getWindowDimensions().then(function(dimensions) {
        t.equal(dimensions.height, 600)
        t.equal(dimensions.width, 900)
    })
    t.end()
})