# Whisper: Stylus [![Build Status](https://travis-ci.org/killdream/whisper-stylus.png)](https://travis-ci.org/killdream/whisper-stylus)

Compiles Stylus stylesheets.


### Example

Define your stylus options in the configuration:

```js
module.exports = function(whisper) {
  whisper.configure({
    stylus: {
      files: ['stylus/*.styl'],
      options: {
        firebug: true,
        linenos: true
      }
    }
  })

  require('whisper-stylus')(whisper)
}
```

Then invoke the `stylus` task:

```bash
$ whisper stylus
```


### Installing

Just grab it from NPM:

    $ npm install whisper-stylus


### Documentation

Just invoke `whisper help stylus` to show the manual page for the `stylus`
task.



### Licence

MIT/X11. ie.: do whatever you want.

[Calliope]: https://github.com/killdream/calliope
[es5-shim]: https://github.com/kriskowal/es5-shim
