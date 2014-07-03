
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
notifier     = new Notification();
path         = require 'path'

debug = require('debug')('glp:gulp-relations')

debug-file = (title, object) -> 
    pp = path.extname(object.path)
    bn = path.basename(object.path)
    debug("#{_.str.pad(title,25)} | -> #{_.str.pad(bn,30)} #pp ")

t = (title) -> 
    return through.obj (object, enc, callback) ->
        debug-file(title, object)
        this.push(object)
        callback()

snake = duplexer

x = (title, head) ->
    tail = t(title)
    head.pipe(tail)
    return snake(head, tail)



# d = (title, args) ->
#     return args ++ [ t(title) ]


conditional-stream = (name, condition, plugin) ->

    # t = (name, stream) -> multipipe(stream, tap(title: name))
    # t = -> it

    stream-split = through.obj()
    # stream-join  = through.obj()
    stream-join = combined.create()

    merged-stream = (s1, s2) ->


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

    # a.pipe(stream-join)
    # b.pipe(stream-join)

    stream-join.append(a)
    stream-join.append(b)

    return duplexer(stream-split, stream-join)

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

module-name = _.pad("glp-rel", 10)

disp-ok = -> 
  winston.info "> #module-name < Ok"
  
disp-ko = -> 
  winston.error "> #module-name < Ok" it.toString()

disp-msg = -> 
  winston.info "> #module-name <   : " it.toString()
  
disp    = winston.info
pdisp   = console.log
pdeb    = winston.warn



_module = ->



    many-to-many = (src, final-dir, options, is-to-one = false) ->

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

        if is-to-one
            debug("Concatenating files #src to #final-dest in #final-dir - temporary build: #{options.temp-build}")
        else   
            debug("Processing files #src to #final-dir")

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
                args := args ++ [ pp() ]

        if is-to-one
            args := args ++ [ gulp.dest options.temp-build ] ++ [ concat(final-dest) ]

        args := args ++ [gulp.dest final-dir]

        stream = multipipe.apply(multipipe, args)

        return stream


    many-to-one = (src, final-dest, options) ->
        many-to-many src, final-dest, options, true
          
    iface = { 
      many-to-one: many-to-one
      many-to-many: many-to-many
    }
  
    return iface
 
module.exports = _module()
