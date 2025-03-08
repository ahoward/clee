class Clee
  VERSION = '0.4.2'

  class << Clee
    def version
      VERSION
    end

    def repo
      'https://github.com/ahoward/clee'
    end

    def summary
      <<~____
        `clee` is a tiny, 0 dependency, DSL for building über clean CLIs in Ruby
      ____
    end

    def description
      <<~____
        `clee` has everything you need, and nothing you don't
      ____
    end

    def libs
      %w[
        optparse
        time
      ]
    end

    def dependencies
      {
      }
    end

    def libdir(*args, &block)
      @libdir ||= File.dirname(File.expand_path(__FILE__))
      args.empty? ? @libdir : File.join(@libdir, *args)
    ensure
      if block
        begin
          $LOAD_PATH.unshift(@libdir)
          block.call
        ensure
          $LOAD_PATH.shift
        end
      end
    end

    def load(*libs)
      libs = libs.join(' ').scan(/[^\s+]+/)
      libdir { libs.each { |lib| Kernel.load(lib) } }
    end

    def load_dependencies!
      libs.each do |lib|
        require lib
      end

      begin
        require 'rubygems'
      rescue LoadError
        nil
      end

      has_rubygems = defined?(gem)

      dependencies.each do |lib, dependency|
        gem(*dependency) if has_rubygems
        require(lib)
      end
    end
  end
end
