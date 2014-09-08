
_        = require 'underscore'
_.str    = require 'underscore.string'
winston  = require 'winston'
path     = require 'path'
es       = require 'event-stream'
path     = require 'path'
debug    = require('debug')('glp:gulp-relations')
chalk    = require('chalk')
concat   = require('gulp-concat')
pass     = require('stream').PassThrough;
to-array = require('stream-to-array')

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

handle-error = (err) ->
    console.log chalk.red(err)
    console.log chalk.red("Terminating")
    process.exit(1)


_module = (gulp) ->

    __ = { }

    tap = (n) ->
        __.observe ->
            console.log chalk.blue("@ #n "), path.basename(it.path), it.contents.length


    # returns a filter from a function f
    __.filter = (f) ->
        es.map (data, cb) ->
            console.log f.toString()
            rez = f(data)
            if _.is-boolean(rez)
                if rez
                    cb(null, data)
                else 
                    cb()

    __.observe = (f) ->
        es.map (data, cb) ->
            rez = f(data)
            cb(null, data)

    __.merge = (sa, name="") ->
        if sa.length == 0
            throw "You must merge at least two streams"

        if sa.length == 1
            return sa[0]

        reduction = (a, n) ->
            m = es.merge(a, n)
            m.on 'error', handle-error
            m

        return _.reduce(_.tail(sa), reduction , sa[0])

    __.pipe = (sa, name="") ->
        if sa.length == 0
            throw "You must pipe at least two streams"

        if sa.length == 1
            return sa[0]

        reduction = (a, n) ->
            p = a.pipe(n)
            p.on 'error', handle-error
            p

        return _.reduce(_.tail(sa), reduction, sa[0])



    build-conditional-stream = (src, filters, name) ->

        source = gulp.src(src)

        if not filters then return source 

        dest   = es.through()

        _.map filters, (f) ->
            f.input = es.through()
            f.output = 
                | _.is-function(f.plugin) => f.input.pipe(f.plugin()) 
                | otherwise => f.input

        merged = __.merge((filters.map (.output)), name)

        to-array source, (err, array) ->

            # console.log _.map(array, (.path))
            for k,file of array
                ff = path: file.path
                for filt in filters 
                    if filt.pred(ff) then 
                        filt.input.write(file)

            for filt in filters
                filt.input.end()

        return merged


    emit = ->
        if process.env.FILTER?
            if path.extname(it.path) in _.words(process.env.FILTER, /,/)
                return true
            return false
        else
            return true

    


    many-to-many = (name, src, final-dir, options, is-to-one) ->

        options ?= {}
        filters = options.compilers
        final-dest = ""

        if is-to-one? and is-to-one
            final-dest := path.basename(final-dir)
            final-dir := path.dirname(final-dir)
            options?.temp-build ?= "#final-dir/build"

            complete = 
                __.pipe [
                    build-conditional-stream(src, filters, name)
                    gulp.dest(options.temp-build)
                    concat(final-dest)
                    gulp.dest(final-dir)
                ]
            return complete    

        else 
            complete =
                __.pipe [
                    build-conditional-stream(src, filters, name)
                    gulp.dest(final-dir)            
                ]
            return complete


    many-to-one = (name, src, final-dest, options) ->
        many-to-many name, src, final-dest, options, true
          
    iface = { 
      many-to-one: many-to-one
      many-to-many: many-to-many
    }
  
    return iface
 
module.exports = _module
