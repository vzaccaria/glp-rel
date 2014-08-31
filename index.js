// Generated by LiveScript 1.2.0
(function(){
  var _, winston, gulp, gif, cache, remember, concat, path, multipipe, Notification, plumber, through, fork, map, combined, passthrough, duplexer, tap, filter, es, notifier, debug, debugFile, t, snake, x, trace, conditionalStream, moduleName, mergeMultiple, _module;
  _ = require('underscore');
  _.str = require('underscore.string');
  winston = require('winston');
  gulp = require('gulp');
  gif = require('gulp-if');
  cache = require('gulp-cached');
  remember = require('gulp-remember');
  cache = require('gulp-cached');
  concat = require('gulp-concat');
  path = require('path');
  multipipe = require('multipipe');
  Notification = require('node-notifier');
  plumber = require('gulp-plumber');
  through = require('through2');
  fork = require('fork-stream');
  map = require('map-stream');
  combined = require('combined-stream');
  passthrough = require('stream').PassThrough;
  duplexer = require('duplexer2');
  tap = require('gulp-debug');
  filter = require("through2-filter");
  es = require('event-stream');
  notifier = new Notification();
  path = require('path');
  debug = require('debug')('glp:gulp-relations');
  debugFile = function(title, object){
    var pp, bn;
    pp = path.extname(object.path);
    bn = path.basename(object.path);
    return debug(_.str.pad(title, 35) + " | -> " + _.str.pad(bn, 30) + " " + pp + " ");
  };
  t = function(title){
    var t;
    t = through.obj();
    return t;
  };
  snake = duplexer;
  x = function(title, head){
    var tail;
    tail = t(title);
    head.pipe(tail);
    return es.duplex(head, tail);
  };
  trace = function(stream){
    var events, i$, len$, e, results$ = [];
    events = ['end', 'finish', 'stop', 'err', 'error', 'done'];
    for (i$ = 0, len$ = events.length; i$ < len$; ++i$) {
      e = events[i$];
      results$.push(stream.on(e, (fn$.call(this, e, e))));
    }
    return results$;
    function fn$(x, e){
      return function(it){
        return debug(x, it);
      };
    }
  };
  conditionalStream = function(name, condition, plugin){
    var streamJoin, streamSplit, toPlugin, noPlugin, a, b;
    streamJoin = es.through();
    streamSplit = es.through();
    toPlugin = filter.obj(function(it){
      var cc;
      cc = condition(it);
      if (cc) {
        debugFile("send to `" + name + "`:", it);
      }
      return cc;
    });
    noPlugin = filter.obj(function(it){
      var cc;
      cc = !condition(it);
      return cc;
    });
    a = streamSplit.pipe(toPlugin).pipe(plumber()).pipe(plugin);
    b = streamSplit.pipe(noPlugin);
    streamJoin = es.merge(a, b);
    return es.duplex(streamSplit, streamJoin);
  };
  _.mixin(_.str.exports());
  _.str.include('Underscore.string', 'string');
  moduleName = _.pad("glp-rel", 10);
  mergeMultiple = function(arr){
    var init, merge;
    debug("Mergin pipe " + arr.length);
    init = es.through();
    merge = function(m, s){
      return m.pipe(s);
    };
    return _.foldl(arr, merge, init);
  };
  _module = function(){
    var sequence, manyToMany, manyToOne, iface;
    sequence = function(g){
      return function(name, arr, code){
        var n, c;
        n = 0;
        debug("Creating " + name + n + " - " + arr[n]);
        c = g.task(name + "" + n, [arr[n]]);
        n = n + 1;
        while (n < arr.length) {
          (fn$.call(this, n));
          n = n + 1;
        }
        debug("Creating " + name + " - dependency: " + name + (n - 1));
        return g.task(name + "", [name + "" + (n - 1)], code);
        function fn$(k){
          debug("Creating " + name + k + " - " + arr[n] + " ");
          g.task(name + "" + k, [name + "" + (k - 1), arr[k]]);
        }
      };
    };
    manyToMany = function(name, src, finalDir, options, isToOne){
      var signalError, wrapPlugin, filters, post, finalDest, args, i$, len$, p, pp, stream;
      isToOne == null && (isToOne = false);
      signalError = function(it){
        notifier.notify({
          message: it
        });
        debug("Error while processing " + src);
        return debug(it);
      };
      wrapPlugin = function(p){
        return p.on('error', signalError);
      };
      options == null && (options = {});
      options.compilers == null && (options.compilers = []);
      filters = options.compilers;
      post = options.post;
      finalDest = "";
      if (isToOne) {
        finalDest = path.basename(finalDir);
        finalDir = path.dirname(finalDir);
        if (options != null) {
          options.tempBuild == null && (options.tempBuild = finalDir + "/build");
        }
      }
      args = [gulp.src(src)];
      if (filters != null) {
        if (!_.isArray(filters)) {
          filters = [filters];
        }
        for (i$ = 0, len$ = filters.length; i$ < len$; ++i$) {
          p = filters[i$];
          args = args.concat([conditionalStream(p.name, p.pred, p.plugin())]);
        }
      }
      if (post != null) {
        if (!_.isArray(post)) {
          post = [post];
        }
        for (i$ = 0, len$ = post.length; i$ < len$; ++i$) {
          pp = post[i$];
          args = args.concat([pp()]);
        }
      }
      if (isToOne) {
        args = args.concat([gulp.dest(options.tempBuild)], [concat(finalDest)]);
      }
      args = args.concat([gulp.dest(finalDir)]);
      debug("Stream " + name + " with " + args.length + " components");
      stream = mergeMultiple(args);
      return stream;
    };
    manyToOne = function(name, src, finalDest, options){
      return manyToMany(name, src, finalDest, options, true);
    };
    iface = {
      manyToOne: manyToOne,
      manyToMany: manyToMany,
      tap: x,
      seq: sequence
    };
    return iface;
  };
  module.exports = _module();
}).call(this);
