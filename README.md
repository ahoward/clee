NAME
----
  `clee`

TL;DR;
--------
  `clee` is a tiny, 0 dependency, DSL for building über clean CLIs in Ruby

INSTALL
-------
  gem install clee

URI
---
  http://github.com/ahoward/clee

ABOUT
-----

`clee` is a minimalist version of `main` (https://github.com/ahoward/main), a
command line DSL i wrote almost 15 years ago, that has seen over [4 million
times](https://drawohara.io/rubygems/)

> why should i use `clee` instead of `main` ?

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

you can use this to decide which to use:

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
