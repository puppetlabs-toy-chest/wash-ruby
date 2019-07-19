# wash

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
#Wash.enable_schema_prefetching

Wash.run(<root_klass>, ARGV)

```

`<root_klass>` should the plugin root's class object. For example, if the plugin root is something like

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

* `init(config)` should not return a value. `config` is a hash containing the plugin config.

* `list` should return an array of `Wash::Entry` objects.

* `read` should return a `String` containing the entry's content.

* `metadata` should return a hash containing the entry's full metadata.

* `stream` should never return during normal operation. `stream` implementations should use the `Wash::Streamer` class when writing their chunks

* `exec(cmd, args, opts)` should return `cmd`'s exit code. `exec` implementations should take advantage of the `Wash::ExecOutputStreamer` class when writing their stdout/stderr chunks. Note that `STDIN`, if provided, can be accessed via the `opts[:stdin]` key.


## Entry Schemas
[Entry schemas](https://puppetlabs.github.io/wash/docs/#entry-schemas) are optional. They can be enabled via the `Wash.enable_entry_schemas` configuration option.

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

