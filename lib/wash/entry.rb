# frozen_string_literal: true

module Wash
  # Entry represents a common base class for Wash entries. All plugin entries
  # should extend this class.
  class Entry
    class << self
      # attributes is a class-level tag specifying all the attributes that
      # make sense for instances of this specific kind of entry. It will
      # pass the specified attributes along to attr_accessor so that instances
      # can set their values. For example, something like
      #
      # @example
      #   class Foo
      #     # Instances of Foo will be able to set the @mtime and @meta fields
      #     attributes :mtime, :meta
      #
      #     def initialize(mtime, meta)
      #       @mtime = mtime
      #       @meta = meta
      #     end
      #   end
      #
      # @param [Symbol] attr An attribute that will be set
      # @param [Symbol] attrs More attributes that will be set
      def attributes(attr, *attrs)
        @attributes ||= []
        @attributes += set_fields(attr, *attrs)
      end

      # slash_replacer is a class-level tag that specifies the slash replacer.
      # It should only be used if there is a chance that instances of the given
      # class can contain a "#" in their names. Otherwise, slash_replacer should
      # be ignored.
      #
      # @example
      #   class Foo
      #     # Tell Wash to replace all "/"es with ":" in the given Foo instance's
      #     # name
      #     slash_replacer ":"
      #   end
      #
      # @param [String] char The slash replacer
      def slash_replacer(char)
        @slash_replacer = char
      end

      # state is a class-level tag that specifies the minimum state required
      # to reconstruct all instances of this specific kind of entry. Each specified
      # state field will be passed along to attr_accessor so that instances can
      # get/set their values.
      #
      # @example
      #   class Foo
      #     # Indicates that api_key is the minimum state required to reconstruct
      #     # instances of Foo. The gem will serialize the api_key as part of each
      #     # instance's state key when passing them along to Wash. If Wash invokes
      #     # a method on a specific instance, then Wash.run will restore the api_key
      #     # prior to invoking the method (so all methods are free to directly reference
      #     # the @api_key field). Thus, plugin authors do not have to manage their entries'
      #     # states; the gem will do it for them via the state tag.
      #     state :api_key
      #
      #     def initialize(api_key)
      #       @api_key = api_key
      #     end
      #   end
      #
      # Note that Wash.run uses {Class#allocate} when it reconstructs the entries, so
      # it does not call the initialize method.
      def state(field, *fields)
        @state ||= []
        @state += set_fields(field, *fields)
      end

      # label is a class-level tag specifying the entry's label. It is a helper for
      # Entry schemas.
      #
      # @param lbl The label.
      def label(lbl)
        @label = lbl
      end

      # is_singleton is a class-level tag indicating that the given Entry's a singleton.
      # It is a helper for Entry schemas.
      #
      # Note that if an Entry has the is_singleton tag and its name is not filled-in
      # when that Entry is listed, then the Entry's name will be set to the specified
      # label. This means that plugin authors do not have to set singleton entries'
      # names, and it also enforces the convention that singleton entries' labels should
      # match their names.
      #
      # @example
      #   class Foo
      #     label 'foo'
      #     # If Foo's instance does not set @name, then the gem will set @name to 'foo'
      #     is_singleton
      #   end
      def is_singleton
        @singleton = true
      end

      # meta_attribute_schema sets the meta attribute's schema to schema. It is a helper
      # for Entry schemas.
      #
      # @param schema A hash containing the meta attribute's JSON schema
      def meta_attribute_schema(schema)
        @meta_attribute_schema = schema
      end

      # metadata_schema sets the metadata schema to schema. It is a helper for Entry schemas.
      #
      # @param schema A hash containing the metadata's JSON schema
      def metadata_schema(schema)
        @metadata_schema = schema
      end

      # parent_of indicates that this kind of Entry is the parent of the given child classes
      # (i.e. child entries). It is a helper for Entry schemas.
      #
      # @example
      #   class Foo
      #     # This indicates that Foo#list will return instances of Bar and Baz. Note
      #     # that both direct class constants (Bar) and strings ('Baz') are valid
      #     # input. The latter's useful when the child class is loaded after the
      #     # parent.
      #     parent_of Bar, 'Baz'
      #   end
      #
      # @param [Wash::Entry] child_klass A child class object.
      # @param [Wash::Entry] child_klasses More child class objects.
      def parent_of(child_klass, *child_klasses)
        @child_klasses ||= []
        @child_klasses += [child_klass] + child_klasses
      end

      # children returns this Entry's child classes. It is a helper for Entry schemas, and
      # is useful for DRY'ing up schema code when one kind of Entry's children matches another
      # kind of Entry's children.
      #
      # @example
      #   class VolumeDir
      #     parent_of 'VolumeDir', 'VolumeFile'
      #   end
      #
      #   class Volume
      #     parent_of *VolumeDir.children
      #   end
      def children
        @child_klasses
      end

      private

      def schema(visited)
        visited[type_id] = {
          label: @label,
          methods: methods,
          singleton: @singleton,
          meta_attribute_schema: @meta_attribute_schema,
          metadata_schema: @metadata_schema,
        }
        unless @child_klasses
          return
        end
        visited[type_id][:children] = @child_klasses
        @child_klasses.each do |child_klass|
          child_klass = const_get(child_klass)
          if visited[child_klass.send(:type_id)]
            next
          end
          child_klass.send(:schema, visited)
        end
      end

      def methods
        wash_methods = Method.instance_variable_get(:@methods)
        methods = []
        self.public_instance_methods.each do |method|
          if wash_methods[method]
            # Only include the Wash methods. This makes the script's output easier
            # to read when debugging.
            methods.push(method)
          end
        end
        unless Wash.send(:entry_schemas_enabled?)
          # Don't include :schema if entry-schema support is not enabled. Otherwise,
          # Wash will return an error since entry schemas are an "on/off" feature.
          methods.delete(:schema)
        end
        methods
      end

      def type_id
        self.name
      end

      def set_fields(field, *fields)
        fields.unshift(field)
        fields.each do |field|
          attr_accessor field
        end
        fields
      end
    end

    # All entries have a name. Note that the name is always
    # included in the entry's state hash.
    attr_accessor :name

    def to_json(*)
      unless @name && @name.size > 0
        unless singleton
          raise "A nameless entry is being serialized. The entry is an instance of #{type_id}"
        end
        @name = label
      end

      hash = {
        type_id: type_id,
        name: @name,
      }

      # Include the methods
      hash[:methods] = self.class.send(:methods).map do |method|
        if prefetched_methods.include?(method)
          [method, self.send(method)]
        else
          method
        end
      end

      # Include the remaining keys. Note that these checks are here to
      # ensure that we don't serialize empty keys. They're meant to save
      # some space.
      if attributes.size > 0 && (attributes_hash = to_hash(attributes))
        hash[:attributes] = attributes_hash
      end
      if cache_ttls.size > 0
        hash[:cache_ttls] = cache_ttls
      end
      if slash_replacer.size > 0
        hash[:slash_replacer] = slash_replacer
      end
      hash[:state] = to_hash(state).merge(klass: type_id, name: @name).to_json
      if Wash.send(:pretty_print?)
        JSON.pretty_generate(hash)
      else
        JSON.generate(hash)
      end
    end

    # type_id returns the entry's type ID, which is its fully-qualified class
    # name.
    def type_id
      self.class.send(:type_id)
    end

    # prefetch indicates that the given methods should be prefetched. This means
    # that the gem will invoke those methods on this particular entry instance and
    # include their results when serializing that entry. Note that the methods are
    # invoked during serialization.
    #
    # @example
    #   class Foo
    #     def initialize(content_size)
    #       if content_size < 10
    #         # content_size < 10, so tell the gem to invoke Foo#list and Foo#read
    #         # on this Foo instance during its serialization
    #         prefetch :list, :read
    #       end
    #     end
    #   end
    #
    # @param [Symbol] method A method that should be prefetched.
    # @param [Symbol] methods More methods that should be prefetched.
    def prefetch(method, *methods)
      prefetched_methods.concat([method] + methods)
    end

    # cache_ttls sets the cache TTLs (time-to-live) of the given methods.
    #
    # @example
    #   class Foo
    #     def initialize(content_size)
    #       if content_size > 10000
    #         # content_size > 10000 so tell Wash to cache its read result for
    #         # 100 seconds
    #         cache_ttls read: 100 
    #       end
    #     end
    #   end
    #
    # @param [Hash] ttls A hash of <method_name> => <method_ttl>
    def cache_ttls(ttls = {})
      @cache_ttls ||= {}
      @cache_ttls = @cache_ttls.merge(ttls)
    end

    # schema returns the entry's schema. It should not be overridden.
    def schema
      schemaHash = {}
      self.class.send(:schema, schemaHash)
      schemaHash
    end

    private

    def attributes
      self.class.instance_variable_get(:@attributes) || []
    end

    def slash_replacer
      self.class.instance_variable_get(:@slash_replacer) || ''
    end

    def state
      self.class.instance_variable_get(:@state) || {}
    end

    def label
      self.class.instance_variable_get(:@label)
    end

    def singleton
      self.class.instance_variable_get(:@singleton)
    end

    def prefetched_methods
      @prefetched_methods ||= []
    end

    def to_hash(fields)
      field_hash = {}
      fields.each do |field|
        field = field.to_sym
        if value = self.send(field)
          field_hash[field] = self.send(field)
        end
      end
      field_hash
    end

    def restore_state(state)
      state.each do |field, value|
        accessor = "#{field}=".to_sym
        unless self.respond_to?(accessor)
          raise "#{field} is an invalid state value"
        end
        self.send(accessor, value)
      end
    end
  end
end
