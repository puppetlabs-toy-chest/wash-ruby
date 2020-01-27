# wash

[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](https://rubydoc.info/github/puppetlabs/wash-ruby)
[![Rubygems](http://img.shields.io/badge/ruby-gems-red.svg)](https://rubygems.org/gems/wash)

## Overview
`wash` is a Ruby gem that's meant to facilitate external plugin development for the [Wash project](https://puppetlabs.github.io/wash/). It does not have any external dependencies.

Plugin scripts that use this gem should adopt the following template:

```
require 'wash'
# All other requires go here

# These are all optional. However, they should be declared
# before the subsequent Wash.run call
#Wash.pretty_print
#Wash.enable_entry_schemas
#Wash.prefetch_entry_schemas

Wash.run(<root_klass>, ARGV)
```

`<root_klass>` is the plugin root's class object. The plugin root must implement the `init` and `list` methods. For example, if the plugin root is something like

```
class MyPluginRoot < Wash::Entry
  def init(config)
    // ...
  end
  
  def list
    // ...
  end
end
```

then the corresponding call to `Wash.run` would be `Wash.run(MyPluginRoot, ARGV)`.

All entries should have their own Ruby class corresponding to a specific kind of entry; this class must extend the `Wash::Entry` base class. For example, a `VirtualMachine` class should represent entries that are virtual machines; a `Database` class represents entries that are databases; a `DockerContainer` class represents Docker containers; a `GoodReadsBook` represents a GoodReads book, etc. Each class should extend the `Wash::Entry` base class.

The entry's supported Wash methods corresponds to instance methods on the entry's class. For example, something like

```
class VirtualMachine < Wash::Entry
  def exec(cmd, args, opts)
    # ...
  end
  
  def stream
    # ...
  end
end
```

implements `stream` and `exec`. The calling conventions and return parameters for each method is described below:

* `init(config)` should not return a value. `config` is a `Hash` containing the plugin config. Only invoked on the plugin root.

* `list` should return an array of `Wash::Entry` objects.

* `read` should return a `String` containing the entry's content. For block-readable entries, `read(size, offset)` should return a `String` containing `size` bits of the entry's content starting at the given offset.

* `metadata` should return a `Hash` containing the entry's full metadata.

* `stream` should never return during normal operation. `stream` implementations should use the `Wash::Streamer` class when writing their chunks

* `exec(cmd, args, opts)` should return `cmd`'s exit code. `exec` implementations should write their stdout/stderr chunks to stdout/stderr. Note that `STDIN`, if provided, can be accessed via the `opts[:stdin]` key.

* `delete` should return `true` if the entry was deleted, `false` if the entry's deletion is in progress.

* `signal(signal)` should return `nil` if the signal was successfully sent.

* `write(data)` should return `nil` if the data's successfully written. Note that `data == STDIN`.

`Wash::Entry` objects must set `@name` (to a `String`) when they're initialized. They may also set `@partial_metadata` (to a `Hash`) if they have metadata that's available at initialization.

## Wash Features
Wash provides two types of core features - _core entries_ and _exec implementations_ - that plugins can use.

_Core entries_ can be used when listing children. See the [external plugin list docs](https://puppetlabs.github.io/wash/docs/external-plugins#list) for more on _core entries_. This gem provides helpers for using the `volume::fs` _core entry_:
```
class Parent < Wash::Entry
  # When 'Wash.enable_entry_schemas' is used the VOLUMEFS entry needs to be included
  parent_of VOLUMEFS, ...
  def list
    [volumefs("fs", maxdepth: 2), ...]
  end
end
```

_Exec implementations_ provide an implementation of the `exec` method so you don't need to define your own. For example if your entry works with SSH, then you can use Wash's SSH transport to implement its exec method. See the [external plugin exec docs](https://puppetlabs.github.io/wash/docs/external-plugins#exec) for more on _exec implementations_, including all the options available for the SSH transport. Request this transport with:
```
class Execable < Wash::Entry
  def initialize(name)
    transport :ssh, host: name, user: 'root'
  end

  # When 'Wash.enable_entry_schemas' is used the 'exec' method still needs to be defined so it appears in the schema
  def exec
    raise 'implemented by transport'
  end
end
```

## Entry Schemas
[Entry schemas](https://puppetlabs.github.io/wash/docs/external-plugins#entry-schemas) are optional. They can be enabled via the `Wash.enable_entry_schemas` configuration option.

The `wash` gem provides convenient helpers for specifying Entry schemas. Below is an example showcasing some of the helpers

```
class Parent < Wash::Entry
  label 'parent'
  is_singleton
  parent_of 'ChildOne', 'ChildTwo'
  
  def list
    # Should return instances of ChildOne/ChildTwo
  end
end

class ChildOne < Wash::Entry
  label 'child_one'
end

class ChildTwo < Wash::Entry
  label 'child_two'
end
```
