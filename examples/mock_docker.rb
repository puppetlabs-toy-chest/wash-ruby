#!/usr/bin/env ruby

require 'wash'

# This example mocks the Docker core-plugin in Wash. It does not perform
# any API calls. It is instead meant to serve as an illustrative example
# showcasing the gem's features.
#
# If you'd like to see this plugin in action, then include the full path
# of this script under the external_plugins key in Wash's config file.
#
# Hint: Try running `stree mock_docker` in the Wash shell. You should see
# a high-level overview of what this plugin contains.

class Root < Wash::Entry
  label 'mock_docker'
  is_singleton
  parent_of 'ContainersDir', 'VolumesDir'
  state :include_image_id

  def init(config)
    @include_image_id = config[:include_image_id]
  end

  def list
    [
      ContainersDir.new(@include_image_id),
      VolumesDir.new
    ]
  end
end

class ContainersDir < Wash::Entry
  label 'mock_containers_dir'
  is_singleton
  parent_of 'Container'
  state :include_image_id

  def initialize(include_image_id)
    @include_image_id = include_image_id
  end

  def list
    image_id = "foo_image"
    containers = {
      # The mtimes correspond to some date in July 2019.
      # You can see their values by running
      # `stat mock_docker/mock_containers/<container>`.
      "wozniak"       => 1563131536,
      "chalice"       => 1563131536,
      "erlang"        => 1563131536,
      "ubuntu_pro"    => 1563477136,
      "debian_dragon" => 1563477136,
    }.map do |name, mtime|
      container_obj = Container.new(name, mtime)
      # Note that the Wash gem will automatically set this field
      # from the given entry's state hash
      if @include_image_id
        container_obj.name = image_id + "::" + container_obj.name
      end
      container_obj
    end
  end
end

class Container < Wash::Entry
  label 'mock_container'
  attributes :mtime, :meta
  state :mtime
  # The "begin", "end" block's used here so that
  # Ruby doesn't confuse "{" with the start of a
  # block.
  meta_attribute_schema = begin
    {
      "type": "object",
      "properties": {
        "last_modified_time": {
          "type": "number",
        },
        "owner": {
          "type": "string",
        }
      }
    }
  end

  def initialize(name, mtime)
    @name = name
    @mtime = mtime
    @meta = {
      last_modified_time: mtime,
      owner: "puppetlabs",
    }
  end

  def stream
    streamer = Wash::Streamer.new
    counter = 0
    # Notice that stream never returns
    while true do
      streamer.write("#{counter}\n")
      counter += 1
      sleep 0.5
    end
  end

  def exec(cmd, args, opts)
    streamer = Wash::ExecOutputStreamer.new
    streamer.write_stdout("CMD = #{cmd}\n")
    streamer.write_stdout("ARGS = #{args}\n")
    streamer.write_stdout("OPTS = #{opts}\n")
    streamer.write_stderr("ERROR = none\n")
    # Notice that exec returns the command's exit code.
    # In this case, the "command execution" was successful.
    0
  end
end

class VolumesDir < Wash::Entry
  label 'mock_volumes_dir'
  is_singleton
  parent_of 'Volume'

  def list
    [
      "volume_one",
      "volume_two"
    ].map do |name|
      Volume.new(name)
    end
  end
end

class Volume < Wash::Entry
  label 'mock_volume'
  # This should be *VolumeDir.children to avoid the duplication;
  # however to do that, we'd need to load the VolumeDir class
  # before Volume which, in this example, is something we are
  # unable to do without breaking the "top-down" presentation
  # style.
  parent_of 'VolumeDir', 'VolumeFile'

  # Note that you are not required to define a constructor for
  # every entry class; this example only does so out of the
  # author's personal preference. To emphasize this point, notice
  # how the VolumeDir/VolumeFile classes do not have an initialize
  # method.
  def initialize(name)
    @name = name
  end

  def list
    dir = VolumeDir.new
    dir.name = "dir"

    file = VolumeFile.new
    file.name = "file"

    [dir, file]
  end
end

class VolumeDir < Wash::Entry
  label 'mock_volume_dir'
  parent_of 'VolumeDir', 'VolumeFile'

  def list
    file = VolumeFile.new
    file.name = "file_in_dir"
    [file]
  end
end

class VolumeFile < Wash::Entry
  label 'mock_volume_file'

  def read
    "Reading #{@name}'s content"
  end
end

Wash.enable_entry_schemas
Wash.pretty_print
Wash.run(Root, ARGV)
