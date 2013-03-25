## Module whisper-stylus
#
# Compiles Stylus stylesheets.
#
# 
# Copyright (c) 2013 Quildreen "Sorella" Motta <quildreen@gmail.com>
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module.exports = (whisper) ->

  ### -- Dependencies --------------------------------------------------
  fs               = require 'fs'
  path             = require 'path'
  glob             = (require 'glob').sync
  stylus           = require 'stylus'
  {merge, Promise} = require 'cassie'

  {unique, concat-map} = require 'prelude-ls'

  ### -- Helpers -------------------------------------------------------

  #### λ read
  # Reads the contents of a file as plain text.
  #
  # :: String -> String
  read = (name) -> fs.read-file-sync name, 'utf-8'


  #### λ write
  # Writes the given contents to a plain text file.
  #
  # :: String -> String -> ()
  write = (contents, name) --> fs.write-file-sync name, contents, 'utf-8'


  #### λ expand
  # Returns a list of files that match a list of glob patterns.
  #
  # :: [String] -> [String]
  expand = (xs or []) -> (unique . (concat-map glob)) xs

  
  #### λ compile-to-css
  # Compiles a single Stylus file to CSS
  #
  # :: Stylus -> String -> String
  compile-to-css = (options, name) -->
    settings = options.options
    c = stylus (read name)
          .set 'filename' name
          .set 'linenos'  (settings.linenos ? false)
          .set 'compress' (settings.compress ? false)
          .set 'firebug'  (settings.firebug ? false)

    (expand (options.paths or [])) .for-each   -> c.include it
    (expand (options.plugins or [])) .for-each -> c.import it
    (options.use or []).for-each               -> c.use it
    for k,v of (options.define or {})          => c.define k, v

    whisper.log.info "Compiling #{path.relative '.', name}."
    p = Promise.make!
    c.render (err, css) ->
      | err => p.fail err
      | _   => p.bind css
    p


  #### λ store-at
  # Stores a resulting CSS at the given location.
  #
  # :: String -> Promise -> Promise
  store-at = (path, promise) -->
    promise.ok (css) -> write css, path


  #### λ build-output-name
  # Builds the output filename for a given file.
  #
  # :: String -> String -> String
  build-output-name = (dir, name) -->
    path.resolve dir, "#{path.basename name, '.styl'}.css"


  #### λ compile-file
  # Compiles a file to CSS and stores in the output path.
  #
  # :: Stylus -> String -> Promise
  compile-file = (options, name) -->
    output = build-output-name options.output, name
    (store-at output, (compile-to-css options, name))
      .ok -> whisper.log.info "Compiled #{path.relative '.', name} -> #{path.relative '.', output}"
    

  #### λ compile-stylus
  # Compiles several stylus stylesheets.
  #
  # :: Promise -> Stylus -> ()
  compile-stylus = (promise, options) ->
    merge ...(expand options.files).map (compile-file options)
      .ok     ~> promise.bind!
      .failed ~> whisper.log.fatal "Failed to compile #it."


  ### -- Tasks ---------------------------------------------------------
  whisper.task 'stylus'
             , []
             , """Compiles Stylus stylesheets to CSS.

               This task allows you to compile Stylus stylesheets to
               CSS. You can specify which files should be compiled, and
               where to look around for other libraries or plugins.

               The configuration should conform to the following
               structure:

               
                   type Stylus {
                     files   : [Pattern]          --^ files to compile
                     output  : String             --^ output directory
                     paths   : [Pattern]          --^ where to look for plugins
                     plugins : [Pattern]          --^ import the plugins
                     define  : { String -> Node } --^ defines nodes
                     use     : [Plugin]           --^ uses the given plugins
                     options : StylusOptions      --^ additional options
                   }

                   type StylusOptions {
                     linenos  : Boolean --^ Adds line numbers to output
                     compress : Boolean --^ Compress the output
                     firebug  : Boolean --^ Instrument for Firebug
                   }

               ## Example

               Compiling your stylesheets in the `/stylus` directory:


                   module.exports = function(whisper) {
                     whisper.configure({
                       stylus: {
                         files: ['stylus/*.styl'],
                         output: 'css'
                         options: {
                           firebug: true,
                           linenos: true
                         }
                       }
                     })
                   }
               """
             , (env) -> do
                        @async = true
                        compile-stylus @promise, env.stylus
             
