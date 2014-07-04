
_            = require 'underscore'
_.str        = require 'underscore.string'
winston      = require 'winston'
gulp         = require 'gulp'
gif          = require 'gulp-if'
cache        = require 'gulp-cached'
remember     = require 'gulp-remember'
cache        = require 'gulp-cached'
concat       = require 'gulp-concat'
path         = require 'path'
multipipe    = require 'multipipe'
Notification = require('node-notifier');
plumber      = require('gulp-plumber')
through      = require('through2');
fork         = require 'fork-stream'
map          = require('map-stream')
combined     = require('combined-stream')
passthrough  = require('stream').PassThrough
duplexer     = require('duplexer2')
tap          = require('gulp-debug')
filter       = require("through2-filter")
es           = require 'event-stream'
notifier     = new Notification();
path         = require 'path'

debug = require('debug')('glp:gulp-relations')

debug-file = (title, object) -> 
    pp = path.extname(object.path)
    bn = path.basename(object.path)
    debug("#{_.str.pad(title,35)} | -> #{_.str.pad(bn,30)} #pp ")

t = (title) -> 
    t = through.obj()
    # t.on 'data', ->
    #     debug-file(title, it)
    # t.on 'end', ->
    #     debug("End: #title")
    # t.on 'finish', ->
    #     debug("finish: #title")
    # t.on 'stop', ->
    #     debug("Stop.")
    return t

snake = duplexer

x = (title, head) ->
    tail = t(title)
    head.pipe(tail)
    return es.duplex(head, tail)



# d = (title, args) ->
#     return args ++ [ t(title) ]

trace = (stream) ->
    events = [ \end \finish \stop \err \error \done ]
    for e in events 
        stream.on e, 
            let x = e
                ->
                    debug(x, it)

conditional-stream = (name, condition, plugin) ->

    # use-th = false 

    stream-join     = es.through()
    stream-split    = es.through()

    to-plugin = filter.obj -> 
        cc = condition(it)
        if cc 
            debug-file "send to `#name`:" it 
        return cc 

    no-plugin = filter.obj ->
        cc = not condition(it)
        # if cc then debug("Not sending to #{it.path} plugin")
        return cc 

    a = stream-split.pipe(to-plugin).pipe(plugin)
    b = stream-split.pipe(no-plugin)

    stream-join = es.merge(a,b)

    # trace stream-join

    return es.duplex(stream-split, stream-join)

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

module-name = _.pad("glp-rel", 10)




merge-multiple = (arr) ->
    debug("Mergin pipe #{arr.length}")
    init = es.through()
    merge = (m, s) ->
        return m.pipe(s)
    return _.foldl arr, merge, init

_module = ->

    sequence = (g) ->
        (name, arr, code) ->
            n = 0
            debug("Creating #name#n - #{arr[n]}")
            c = g.task "#name#n", [arr[n]]
            n = n + 1
            while n < arr.length
                let k = n
                    debug("Creating #name#k - #{arr[n]} ")
                    g.task "#name#k", [ "#name#{k-1}", arr[k] ]
                n = n + 1
            debug("Creating #name - dependency: #name#{n-1}")
            g.task "#name", [ "#name#{n-1}" ], code


    many-to-many = (name, src, final-dir, options, is-to-one = false) ->

        signal-error = ->
            notifier.notify message: it
            debug "Error while processing #src"
            debug it

        wrap-plugin = (p) ->
            p.on 'error', signal-error

        options ?= {}
        options.compilers ?= []

        filters = options.compilers
        post    = options.post

        final-dest = ""

        if is-to-one
            final-dest := path.basename(final-dir)
            final-dir := path.dirname(final-dir)
            options?.temp-build ?= "#final-dir/build"

        # if is-to-one
        #     debug("Concatenating files #src to #final-dest in #final-dir - temporary build: #{options.temp-build}")
        # else   
        #     debug("Processing files #src to #final-dir")

        args = [ gulp.src(src) ]

        # args = args ++ [plumber()]

        if filters? 
            if not _.is-array(filters)
                filters := [filters]

            for p in filters 
                args := (args ++ [ conditional-stream(p.name, p.pred, p.plugin())])

        if post? 
            if not _.is-array(post)
                post := [ post ]

            for pp in post 
                args := (args ++ [ pp() ])

        if is-to-one
            args := args ++ [ (gulp.dest options.temp-build) ] ++ [ concat(final-dest) ]

        args := (args ++ [ (gulp.dest final-dir)])

        debug("Stream #name with #{args.length} components") 
        # for e in args 
            # debug(e._events)
        stream = merge-multiple(args)

        return stream


    many-to-one = (name, src, final-dest, options) ->
        many-to-many name, src, final-dest, options, true
          
    iface = { 
      many-to-one: many-to-one
      many-to-many: many-to-many
      tap: x 
      seq: sequence
    }
  
    return iface
 
module.exports = _module()
