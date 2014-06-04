
_        = require 'underscore'
_.str    = require 'underscore.string'
winston  = require 'winston'
gulp     = require 'gulp'
gif      = require 'gulp-if'
cache    = require 'gulp-cached'
remember = require 'gulp-remember'
cache    = require 'gulp-cached'
concat   = require 'gulp-concat'
plumber  = require 'gulp-plumber'
path     = require 'path'

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

    many-to-many = (src, final-dir, options) ->

        options ?= {}
        options.compilers ?= []

        pre = gulp.src src
                .pipe plumber()
                .pipe cache final-dir

        predicates = options.compilers

        if predicates? and _.is-array(predicates)

            for p in predicates 
                pre := pre.pipe gif(p.pred, p.plugin)

        else if predicates?
                pre := pre.pipe gif(predicates.pred, predicates.plugin)

        if options.post? and _.is-function(options.post)
            pre := pre.pipe options.post 

        if options.post? and _.is-array(options.post) 
            for pp in options.post 
                pre := pre.pipe pp


        pre := pre.pipe gulp.dest final-dir

        return pre


    many-to-one = (src, final-dest, options) ->

        options ?= {}

        final-cache = final-dest

        final-dir = path.dirname(final-dest)
        final-dest = path.basename(final-dest)

        options?.temp-build ?= "#final-dir/build"
        options.compilers ?= []

        predicates = options.compilers

        pre = gulp.src src
                .pipe plumber()
                .pipe cache final-cache

        if predicates? and _.is-array(predicates)
            for p in predicates 
                pre := pre.pipe gif(p.pred, p.plugin)
        else if predicates?
                pre := pre.pipe gif(predicates.pred, predicates.plugin)

        pre := pre.pipe gulp.dest options.temp-build
                .pipe remember(final-cache)
                .pipe concat final-dest

        if options.post? and _.is-function(options.post)
            pre := pre.pipe options.post 

        if options.post? and _.is-array(options.post) 
            for pp in options.post 
                pre := pre.pipe pp

        pre := pre.pipe gulp.dest final-dir

        return pre
          
    iface = { 
      many-to-one: many-to-one
      many-to-many: many-to-many
    }
  
    return iface
 
module.exports = _module()
