NAME
----
  `clee`

TL;DR;
--------
  `clee` is a tiny, 0 dependency, DSL for building über clean CLIs in Ruby

INSTALL
-------
```sh
  gem install clee
```

URI
---
  http://github.com/ahoward/clee

ABOUT
-----

`clee` is a minimalist version of `main` (https://github.com/ahoward/main), a
command line DSL i wrote almost 15 years ago, that has seen over [4 million
downloads](https://drawohara.io/rubygems/)

> then why should i use `clee` instead of `main` ?

* `clee` has 0 dependencies beyond ruby itself

* `clee` is very very small
  ```sh
    drawohara@drawohara.dev:ahoward #=> loc clee/lib

    clee/lib/clee.rb: 478
    ===
    @loc: 478


    drawohara@drawohara.dev:ahoward #=> loc main/lib

    main/lib/main/cast.rb: 139
    main/lib/main/daemon.rb: 395
    main/lib/main/dsl.rb: 65
    main/lib/main/factories.rb: 24
    main/lib/main/getoptlong.rb: 245
    main/lib/main/logger.rb: 43
    main/lib/main/mode.rb: 41
    main/lib/main/parameter.rb: 589
    main/lib/main/program/class_methods.rb: 362
    main/lib/main/program/instance_methods.rb: 274
    main/lib/main/program.rb: 6
    main/lib/main/softspoken.rb: 12
    main/lib/main/stdext.rb: 34
    main/lib/main/test.rb: 69
    main/lib/main/usage.rb: 159
    main/lib/main/util.rb: 96
    main/lib/main.rb: 70
    ===
    @loc: 2623
  ```

* you can use this to decide which to use:

```ruby
  case
    when wants?(:simple, :tiny, :scripting)
      :clee

    when wants?(:powerful, :testable, :complete, :mature)
      :main

    else
      [:clee, :main].sort_by{ rand }.first
  end
```

API
---

`clee`'s api is very simple.  it has every feature you need, and none that you
don't, including:

- auto generated help messages
- support for `my_clee --help` and `my_clee help` to 'just work'
- support for modifying help/usage messages simply
- sane exit codes
- support for --options, env=val pairs, etc
- argv parsing
- fancy color'd logging
- modes, and sub-modes

the smallest clee script looks like this

```ruby
require 'clee'

clee do
  run do
    p 42
  end
end
```

you can name your scripts

```ruby
require 'clee'

clee do
  run do
    help!  #=> this will print a default usage message that will include 'my_clee'
  end
end
```

you can alter the default tldr, and help messages

```ruby
require 'clee'

clee do
  tldr <<~____
    avoid using the default 'tldr'
  ____
end
```

```ruby
require 'clee'

clee do
  help <<~____
    NAME
      my_clee

    USAGE
      fully custom help...
  ____
end
```

specifying params is trivial

```ruby
require 'clee'

clee do
# support `my_clee --verbose` and -v
#
  option :verbose, :v

# support `my_clee --path=./lib`
#
  option :path, value: :required

# support `my_clee API_KEY=123` *and* `API_KEY=123 my_clee`
#
  env :API_KEY

# support `my_clee --foo=42` *and* `my_clee foo=42` *and* `foo=42 my_clee` syntax
#
  param :foo, value: 'required'

# the interface and help messages work the same way for all the above
#
  def run
    if @options.has_key?(:verbose)
      @verbose = true
    end

    @path = @options.fetch(:path)

    @api_key = @env.fetch(:API_KEY)

    @foo = @parms.fetch(:foo)
  end
end
```

modes, and sub-modes, are supported

```ruby
require 'clee'

clee :my_clee do
  run :foo do
    p 42
  end

  run :foo, :bar do
    p 42.0
  end

  run do
    p 42.42
  end
end
```

assuming you saved the above as `my_clee`, you could then do
```sh
  ~> my_clee foo     #=> 42
  ~> my_clee foo bar #=> 42.0
  ~> my_clee         #=> 42.42
```

`clee` scripts have a sweet dependency-less colored logger that understands what a #tty really is...
```ruby
require 'clee'

clee do
  def run
    log 'hai!'
    log 'hai!', level: :warning
    log 'blue', color: :blue
  end
end
```

`clee` ships with a lil code-gen-thang
```sh
~> clee new my_clee > my_clee
~> chmod 755 my_clee
~> ./my_clee
```

i could write more docs but, they would then outnumber the LOC of the library
so:

1. see [./lib/clee.rb](./lib/clee.rb)
2. if that still doesn't float your boat install `ima`, a universal
command-line filter built on `clee`, that brings AI to your CLI and do
something like this

```sh
  ~> gem install clee ima
  ~> ima explain clee to me --context=$(gem which clee)
```

which might produce something like this ->

---

Clee is a Ruby library that provides a simple way to create command-line interfaces (CLI) for Ruby applications. It allows developers to define commands, options, and parameters for their application, and handles the parsing and execution of these commands.

The core features of Clee include:

* Command definition: Clee allows developers to define commands and their associated options and parameters.
* Option parsing: Clee can parse command-line options and parameters, and provides a simple way to define and handle these options.
* Parameter handling: Clee provides a way to handle command-line parameters, including required and optional parameters.
* Help generation: Clee can generate help text for commands and options, making it easy to provide documentation for users.
* Logging: Clee provides a logging mechanism that allows developers to log messages at different levels (e.g. debug, info, warning, error).

Clee is designed to be flexible and customizable, making it easy to integrate into existing Ruby applications. It also provides a number of features that make it easy to use, including automatic help generation and logging.

Some of the key concepts in Clee include:

* Commands: These are the top-level actions that a user can perform with the application.
* Options: These are the flags or switches that can be used to modify the behavior of a command.
* Parameters: These are the values that are passed to a command or option.
* Modes: These are alternative behaviors that a command can exhibit, depending on the options or parameters passed to it.

Overall, Clee is a powerful and flexible library that makes it easy to create command-line interfaces for Ruby applications. Its simple and intuitive API makes it easy to use, even for developers who are new to CLI development.

---

SING IT 🎵
----------
* **DOCS are dead, long live AI!**
* **UIs are dead, long live CLIS!**

FINALLY
-------
> why `clee`, that is honestly such a stupid name...

a good friend used to pronounce 'cli' as 'clee'.  it stuck.  i like it.
