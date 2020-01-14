# frozen_string_literal: true

module Wash
  # @api private
  module Method
    def self.invoke(method, entry, *args)
      method = method.to_sym
      unless entry.respond_to?(method)
        raise "Entry #{entry.name} (#{entry.type_id}) does not implement #{method}"
      end
      unless invocation = @methods[method]
        raise "#{method} is not a supported Wash method"
      end
      invocation.call(entry, *args)
    end
    private_class_method :invoke

    def self.method(name, &block)
      name = name.to_sym
      unless block
        block = lambda do |entry, *args|
          result = entry.send(name, *args)
          unless result == nil
            Wash.send(:print_json, result)
          end
        end
      end
      @methods ||= {}
      @methods[name] = block
    end
    private_class_method :method

    method(:list)
    method(:metadata)
    method(:schema)
    method(:delete)
    method(:signal)

    method(:read) do |entry, *args|
      if args.length > 0
        # We're invoking read on a block-readable entry so munge
        # the size and offset
        args = args.map(&:to_i)
      end
      STDOUT.print(entry.read(*args))
    end

    method(:write) do |entry, _|
      entry.write(STDIN)
    end

    method(:exec) do |entry, *args|
      opts, cmd, args = Wash.send(:parse_json, args[0]), args[1], args[2..-1]
      if opts[:stdin]
        opts[:stdin] = STDIN
      else
        opts[:stdin] = nil
      end
      ec = entry.exec(cmd, args, opts)
      exit ec
    end

    method(:stream) do |entry, _|
      entry.stream
      raise "stream should never return"
    end
  end
end
