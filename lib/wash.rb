# frozen_string_literal: true

require 'json'

module Wash
  # pretty_print enables pretty printing of methods that produce
  # JSON output. It is a useful debugging tool.
  def self.pretty_print
    @pretty_print = true
  end

  # enable_entry_schemas enables {Entry schema}[https://puppetlabs.github.io/wash/docs/#entry-schemas]
  # support. See Wash::Entry's documentation for more details on
  # the available Entry schema helpers.
  def self.enable_entry_schemas
    @entry_schemas_enabled = true
  end

  # prefetch_entry_schemas enables schema-prefetching. This option
  # should be enabled once external plugin development's finished.
  # If the external plugin is not using Entry schemas, then this
  # option can be ignored.
  def self.prefetch_entry_schemas
    @prefetch_entry_schemas = true
  end

  # on_sigterm will execute the provided block when the plugin script
  # receives a SIGTERM/SIGINT signal. It is useful for handling
  # plugin-specific cleanup like dangling processes, files, etc.
  def self.on_sigterm(&block)
    @sigterm_handlers ||= []
    @sigterm_handlers << block
  end

  # run is the plugin script's run function. All plugin scripts using
  # this gem should invoke this function once they've specified the
  # desired configuration options (e.g. like pretty_print).
  #
  # @param [Wash::Entry] root_klass The plugin root's class object
  #
  # @param [Array<String>] argv The plugin script's arguments. This
  # should almost always be the ARGV global variable.
  def self.run(root_klass, argv)
    Signal.trap('INT') do
      handle_sigterm
      exit 130
    end
    Signal.trap('TERM') do
      handle_sigterm
      exit 143
    end

    method, argv = next_arg(argv)

    if method == "init"
      config, argv = next_arg(argv)
      root = root_klass.new
      unless root.respond_to?(:init)
        raise "Plugin root #{root.type_id} does not implement init."
      end
      config = parse_json(config)
      root.init(config)
      if @prefetch_entry_schemas
        root.prefetch :schema
      end
      print_json(root)
      return
    end

    _, argv = next_arg(argv)

    state, argv = next_arg(argv)
    state = parse_json(state)
    klass = const_get(state.delete(:klass))
    # Use klass#allocate instead of klass#new to give plugin authors
    # more freedom in how they decide to setup their constructors
    entry = klass.allocate
    entry.send(:restore_state, state)

    Method.send(:invoke, method, entry, *argv)
  end

  def self.next_arg(argv)
    if argv.size < 1
      raise "Invalid plugin-script invocation. See https://puppetlabs.github.io/wash/docs/external_plugins/ for details on what this should look like"
    end
    return argv[0], argv[1..-1]
  end
  private_class_method :next_arg

  def self.handle_sigterm
    @sigterm_handlers.each do |handler|
      handler.call
    end
  end
  private_class_method :handle_sigterm

  def self.pretty_print?
    @pretty_print
  end
  private_class_method :pretty_print?

  def self.entry_schemas_enabled?
    @entry_schemas_enabled
  end
  private_class_method :entry_schemas_enabled?

  def self.print_json(result)
    if pretty_print?
      result_json = JSON.pretty_generate(result)
    else
      result_json = JSON.generate(result)
    end
    puts(result_json)
  end
  private_class_method :print_json

  def self.parse_json(json)
    JSON.parse(json,:symbolize_names => true)
  end
  private_class_method :parse_json

  require 'wash/entry'
  require 'wash/method'
  require 'wash/streamer'
end
