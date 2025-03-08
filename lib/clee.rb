# -*- encoding : utf-8 -*-
#
  require_relative 'clee/_lib.rb'

  Clee.load_dependencies!

#
  class Clee
    class Error < ::StandardError; end

    attr_accessor :env
    attr_accessor :argv
    attr_accessor :options
    attr_accessor :params
    attr_accessor :stdin
    attr_accessor :stdout
    attr_accessor :stderr
    attr_accessor :help

    def _run!
      _setup!
      _parse_command_line!
      _set_mode!
      _run_mode!
    end

    def _setup!
      @klass = self.class

      @env = Hash.new
      @options = Hash.new

      @argv = ARGV.map(&:dup)

      @stdin = $stdin.dup
      @stdout = $stdout.dup
      @stderr = $stderr.dup

      @name = @klass.name.dup
      @help = @klass.help.dup
      @tldr = @klass.tldr.dup
    end

    def _parse_command_line!
      _parse_options!
      _parse_env!
      _parse_params!
    end

    def _parse_options!
      @options = Hash.new

      o = OptionParser.new

      klass.options.each do |spec|
        spec => long:, short:, value:
        args = []

        case value
          when :required
            args.push "-#{ short }" if short
            args.push "--#{ long } value" if long
          when :optional
            args.push "-#{ short }" if short
            args.push "--#{ long } [value]" if long
          when :none
            args.push "-#{ short }" if short
            args.push "--[no-]#{ long }" if long
        end

        o.on(*args) do |val|
          if @options.has_key?(long)
            @options[long] = [@options[long], val].flatten
          else
            @options[long] = val
          end
        end
      end

      begin
        o.parse!(@argv)
      rescue OptionParser::MissingArgument => e
        warn(e.message)
        exit 1
      rescue OptionParser::InvalidOption => e
        warn(e.message)
        exit 1
      end

      Clee.symbolize_keys!(@options)
    end

    def _parse_env!
    #
      envs = Hash.new

      @argv.each_with_index do |arg, index|
        if arg =~ /[^=]+\s*=/
          k, v = arg.split(/\s*=\s*/, 3)

          key = k.to_s.strip.to_sym
          val = v.to_s.strip == '' ? nil : v

          envs[index] = {key:, val:}
        end
      end

    #
      validate = proc do |long:, value:, val:|
        case value
          when :required
            unless val
              warn("#{ long }=:missing")
              exit 1
            end

          when :none
            unless val.nil?
              warn("#{ long }=#{ val }")
              exit 1
            end

          when :optional
            :noop
        end
      end

    #
      add_env = proc do |long, val|
        if @env.has_key?(long)
          @env[long] = [@env[long], val].flatten
        else
          @env[long] = val
        end
      end

      klass.envs.each do |spec|
        spec => long:, short:, keys:, value:

        keys.reverse.each do |key|
          if ENV.has_key?(key.to_s)
            v = ENV[key.to_s]
            val = v.to_s.strip == '' ? nil : v
            validate[long:, value:, val:]
            add_env[long, val]
          end
        end

        envs.each do |index, env|
          env => key:, val:

          if([long, short].include?(key))
            validate[long:, value:, val:]
            add_env[long, val]
            @argv[index] = nil
          end
        end
      end

    #
      @argv.compact!

      Clee.symbolize_keys!(@env)
    end

    def _parse_params!
      @params = @env.merge(@options)
    end

    def _set_mode!
      @mode = nil

      first = 0
      last = @argv.size

      while last > 0
        args = @argv[first ... last]
        mode = klass.mode?(*args)

        if mode
          @mode = mode
          @argv.replace(@argv[last..])
          break
        end

        last = last - 1
      end
    end

    def _run_mode!
      if @mode
        mode_method = klass.mode_method_for(@mode)
        send(mode_method)
        exit 0
      end

      if argv.first == 'help' || params[:help]
        help!(exit: 0)
      end

      send(:run)
      exit 0
    end

    def _default_run!
      help!(exit: 1)
    end

    def run
      _default_run!
    end

    def progname
      File.basename($0)
    end

    def help!(**kws)
      help = (@help || _default_help)
      puts help
      status = kws.fetch(:exit){ kws.fetch('exit'){ 1 } }
      exit(status.to_i) if status
    end

    def _default_help
      [].tap do |l|
        p = proc do |string|
          l.push string.to_s.rstrip
          l.push "\n"
        end

        h = proc do |header|
          l.push "\n"
          p[header]
          p['_' * header.to_s.size]
        end

        h[:NAME]
        p["  #{ progname }"]

        if @tldr
          h[:TLDR]
          p["  #{ @tldr }"]
        end

        unless klass.envs.empty?
          h[:ENVIRONMENT]
          klass.envs.each do |spec|
            spec => value:, keys:

            if value == :none
              p["  #{ keys.join(' | ') }"]
            else
              p["  #{ keys.join(' | ') } : value=#{ value }"]
            end
          end
        end

        unless klass.options.empty?
          h[:OPTIONS]
          klass.options.each do |spec|
            spec => value:, opts:

            if value == :none
              p["  #{ opts.join(' | ') }"]
            else
              p["  #{ opts.join(' | ') } : value=#{ value }"]
            end
          end
        end


        h[:MODES]
        p["  ~> #{ progname }"]
        modes.each do |mode|
          p["  ~> #{ progname } #{ mode.join ' ' }"]
        end
        p["  ~> #{ progname } help"]

      end.join.strip
    end
  #
    def Clee.deep_copy(obj)
      Marshal.load(Marshal.dump(obj))
    end

    def Clee.symbolize_keys!(hash)
      hash.transform_keys!(&:to_sym)

      hash.each do |key, val|
        if val.is_a?(Hash)
          symbolize_keys!(val)
        end
      end

      hash
    end

    def Clee.stringify_keys(hash)
      stringify_keys!(deep_copy(hash))
    end

    def Clee.stringify_keys!(hash)
      hash.transform_keys!(&:to_sym)

      hash.each do |key, val|
        if val.is_a?(Hash)
          stringify_keys!(val)
        end
      end

      hash
    end

    def Clee.stringify_keys(hash)
      stringify_keys!(deep_copy(hash))
    end

  #
    def klass
      self.class
    end

    def Clee.klass
      self
    end

  #
    ANSI = {
      :clear      => "\e[0m",
      :reset      => "\e[0m",
      :erase_line => "\e[K",
      :erase_char => "\e[P",
      :bold       => "\e[1m",
      :dark       => "\e[2m",
      :underline  => "\e[4m",
      :underscore => "\e[4m",
      :blink      => "\e[5m",
      :reverse    => "\e[7m",
      :concealed  => "\e[8m",
      :black      => "\e[30m",
      :red        => "\e[31m",
      :green      => "\e[32m",
      :yellow     => "\e[33m",
      :blue       => "\e[34m",
      :magenta    => "\e[35m",
      :cyan       => "\e[36m",
      :white      => "\e[37m",
      :on_black   => "\e[40m",
      :on_red     => "\e[41m",
      :on_green   => "\e[42m",
      :on_yellow  => "\e[43m",
      :on_blue    => "\e[44m",
      :on_magenta => "\e[45m",
      :on_cyan    => "\e[46m",
      :on_white   => "\e[47m"
    }

    Ansi = Object.new

    ANSI.each do |key, value|
      Ansi.singleton_class.define_method(key){ value }
    end

    def Clee.ansi
      @ansi ||= Ansi
    end

    def ansi
      klass.ansi
    end

  #
    class Logger
      Levels = [
        :success,
        :failure,
        :message,
        :warning,
        :special,
      ]

      Colors = {
        success: Ansi.green,
        failure: Ansi.red,
        message: Ansi.cyan,
        default: Ansi.blue,
        warning: Ansi.yellow,
        special: Ansi.magenta,
        clear: Ansi.clear,
      }

      def initialize(io = $stderr)
        @io = io
      end

      def log(arg, *args, **kws)
        level = kws.fetch(:level){ :message }
        color = kws[:color] ? Ansi.public_send(kws[:color]) : color_for(level)
        clear = color_for(:clear)

        [arg, *args].each do |arg|
          ts = Time.now.utc.iso8601(2)
          msg = msg_for(arg)

          prefix = "### [#{ level.to_s.upcase } @ #{ ts }]"

          if @io.tty?
            @io.write(color)
            @io.write(prefix)
            @io.write(clear)
          else
            @io.write(prefix)
          end

          @io.write("\n#{ msg }\n")
          @io.flush
        end
      end

      Levels.each do |level|
        define_method(level){|arg, *args| log(arg, *args, level:)}
      end

      def color_for(level)
        Colors.fetch(level.to_s.to_sym){ Colors.fetch(:default) }
      end

      def msg_for(arg)
        case
          when arg.is_a?(String)
            arg.strip
          when arg.is_a?(Exception)
            "#{ e.message } (#{ e.class.name })\n#{ Array(e.backtrace).join(10.chr) }"
          else
            arg.pretty_inspect
        end
      end
    end

    def Clee.logger
      @@logger ||= Logger.new
    end

    def logger
      klass.logger
    end

    def log(*args, **kws, &block)
      return logger if args.empty? && kws.empty? && block.nil?

      logger.message(*args, **kws, &block)
    end

    def emsg(e)
      if e.is_a?(Exception)
        "#{ e.message } (#{ e.class.name })\n#{ Array(e.backtrace).join(10.chr) }"
      else
        e.to_s
      end
    end

  #
    def Clee.parse_spec(list, *args, **kws, &block)
      return list if args.empty? && kws.empty? && block.nil?

      argv = []

      args.each do |arg|
        if arg.is_a?(Hash)
          kws.update(Clee.symbolize_keys(arg))
        else
          argv.push(arg)
        end
      end

      long = kws.fetch(:long){ argv.shift }
      raise ArgumentError.new('long=nil') unless long
      long = long.to_s.to_sym

      short = kws.fetch(:short){ argv.shift }

      value = kws.fetch(:value){ :none }.to_s.to_sym

      values = [:none, :required, :optional]

      raise ArgumentError.new("value=#{ value }") unless values.include?(value)

      keys = [long, short].compact

      opts = [(long && "--#{ long }"), (short &&"-#{ short}")].compact

      spec = {long:, short:, value:, keys:, opts:}

      list.push(spec).uniq!
    end

    def Clee.options(*args, **kws, &block)
      parse_spec(@@options ||= [], *args, **kws, &block)
    end

    def Clee.option(*args, **kws, &block)
      options(*args, **kws, &block)
    end

    def Clee.opt(*args, **kws, &block)
      options(*args, **kws, &block)
    end

    def Clee.envs(*args, **kws, &block)
      parse_spec(@@envs ||= [], *args, **kws, &block)
    end

    def Clee.env(*args, **kws, &block)
      envs(*args, **kws, &block)
    end

    def Clee.params(*args, **kws, &block)
      parse_spec(@@options ||= [], *args, **kws, &block)
      parse_spec(@@envs ||= [], *args, **kws, &block)

      @@options + @@envs
    end

    def Clee.param(*args, **kws, &block)
      params(*args, **kws, &block)
    end

    def Clee.help(*args)
      @help ||= nil

      unless args.empty?
        @help = args.join("\n")
      end

      @help
    end

    def Clee.tldr(*args)
      @tldr ||= nil

      unless args.empty?
        @tldr = args.join("\n")
      end

      @tldr
    end

    def Clee.run(*args, **kws, &block)
      if args.empty?
        method = :run
      else
        mode = mode_for(*args)
        klass.modes.push(mode).uniq!
        method = mode_method_for(mode)
      end

      define_method(method, &block)
    end

    def Clee.mode_for(*args)
      args.flatten!
      args.compact!

      return nil if args.empty?

      args.map(&:to_s).map(&:to_sym)
    end

    def Clee.modes
      @@modes ||= []
    end

    def modes
      klass.modes
    end

    def Clee.mode?(*args)
      mode = mode_for(*args)
      return mode if modes.include?(mode)
    end

    def Clee.mode_method_for(mode)
      "__mode__#{ [mode].join('__') }"
    end

  #
    def Clee.klass_for(name = 'clee', &block)
      Class.new(Clee).tap do |klass|
        klass.class_eval do
          define_singleton_method(:name){ "#{ name }" }

          option(:help, :h, value: :none)
        end

        klass.class_eval(&block)
      end
    end

    def Clee._run!(name = 'clee', *args, &block)
      $stdout.sync = true
      $stderr.sync = true

      %w[ PIPE INT ].each{|signal| Signal.trap(signal, "EXIT")}

      klass = Clee.klass_for(name, &block)

      clee = klass.new

      clee._run!(*args)
    end
  end

BEGIN { 
  Object.send(:remove_const, :Clee) if Object.const_defined?(:Clee)

  def Clee(*args, &block)
    clee(*args, &block)
  end

  def clee(name = 'clee', *args, &block)
    Clee._run!(name, *args, &block)
  end
}
