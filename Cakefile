{exec} = require "child_process"
fs     = require 'fs'
{IM}     = require './intermine.spec'

header = """
  ###
   * InterMine Results Tables Library v#{IM.VERSION}
   * http://www.intermine.org
   *
   * Copyright 2012, Alex Kalderimis
   * Released under the LGPL license.
   * 
   * Built at #{new Date()}
  ###
"""

cont = (cb) ->
    cb() if typeof cb is 'function'

task 'copyright', 'Show the copyright header', ->
    console.log header

task 'build:compile', 'Build project from build/* to js/imtables.js', compile = (cb) ->
    console.log "Compiling #{IM.NAME} (#{IM.VERSION}) to /js"
    exec 'coffee --compile --join js/imtables.js build/', (err, stdout, stderr) ->
        if err
            console.log "Compilation failed:", stdout + stderr
            exec "notify-send 'Compilation Failed' '#{ err + stdout + stderr }'", cb
        else
            cont cb

writing = false

neededEarly = ["shiv.coffee", "module.coffee", "icons.coffee", "options.coffee", "constraintadder.coffee"]

task 'build:concat',
    'Concatenate the source files to a single application script',
    concat = (cb) ->
        console.log "Building source file"
        unless writing
            writing = true
            fs.readdir 'src', (err, files) ->
                appContents = new Array remaining = files.length
                throw err if err
                files = neededEarly.concat (f for f in files when f not in neededEarly)
                for f, i in files then do (f, i) ->
                    fs.readFile "src/#{f}", 'utf8', (err, fileContents) ->
                        appContents[i] = fileContents
                        process(appContents) if --remaining is 0
        process = (texts) ->
            console.log "Writing build"
            fs.writeFile 'build/build.coffee', header + "\n\n" + texts.join('\n\n'), 'utf8', (err) ->
                writing = false
                throw err if err
                cont cb

writingDeps = false

otherDeps = ["lib/raphael-min.js", "lib/google-code-prettify/prettify.js", "lib/jquery-ui-1.8.19.custom.js"]

task 'build:deps', 'concatenate dependencies', builddeps = (cb) ->
    console.log "Building deps"
    unless writingDeps
        writingDeps = true
        fs.readdir "lib/bootstrap/js", (err, files) ->
            throw err if err
            wanted = ("lib/bootstrap/js/#{f}" for f in files when f.match(/\.js$/) and not f.match(/(scrollspy|carousel|collapse)/))
            wanted = wanted.concat otherDeps
            depContents = new Array remaining = wanted.length
            for f, i in wanted then do (f, i) ->
                fs.readFile f, "utf8", (err, fileContents) ->
                    depContents[i] = fileContents
                    process(depContents) if --remaining is 0
        process = (texts) ->
            console.log "Writing deps"
            fs.writeFile 'js/deps.js', texts.join('\n\n'), 'utf8', (err) ->
                writing = false
                throw err if err
                cont cb

cleaning = false

task 'clean:js', 'Remove old js', cleanjs = (cb) ->
    jsf = "js/imtables.js"
    fs.stat jsf, (err, stats) ->
        if stats? and not cleaning
            cleaning = true
            console.log "Removing old compiled js"
            fs.unlink jsf, (err) ->
                cleaning = false
                throw err if err
                cont cb
        else
            cont cb

task 'clean:build', 'Remove old build', cleanbuild = (cb) ->
    buildf = "build/build.coffee"
    fs.stat buildf, (err, stats) ->
        if stats? and not cleaning
            cleaning = true
            console.log "Removing old build"
            fs.unlink buildf, (err) ->
                cleaning = false
                throw err if err
                cont cb
        else
            cont cb

task 'clean', "Remove old artifacts", clean = (cb) ->
    cleanbuild ->
        cleanjs ->
            console.log "Cleaned up"
            cont cb

task 'build:setup', 'Set things up for building', prebuild = (cb) ->
    console.log "Checking for build directory"
    fs.stat "build", (err, stats) ->
        if stats?
            cont cb
        else
            fs.mkdir "build", "770", ->
                cont cb

task 'build', 'Run a complete build', ->
    clean ->
        prebuild ->
            builddeps ->
                concat ->
                    compile ->
                        console.log "done at #{new Date()}"

task 'watch', 'Watch production files and rebuild the application', watch = (cb) ->
    console.log "Watching for changes in ./src"
    fs.readdir 'src', (err, files) ->
        throw err if err
        for f in files then do (f) ->
            fs.watchFile "src/#{f}", (curr, prev) ->
                if +curr.mtime isnt +prev.mtime
                    console.log "Saw change in js/#{f} - rebuilding"
                    invoke 'build'
    

# vim: set syntax=coffee
