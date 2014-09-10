module RGeo
  module ActiveRecord
    # The default factory generator for ActiveRecord::Base.

    DEFAULT_FACTORY_GENERATOR = ::Proc.new do |config|
      if config.delete(:geographic)
        ::RGeo::Geographic.spherical_factory(config)
      else
        ::RGeo::Cartesian.preferred_factory(config)
      end
    end

    # An object that manages the RGeo factories for a ConnectionPool.
    class RGeoFactorySettings

      def initialize  # :nodoc:
        @factory_generators = {}
        @column_factories = {}
      end

      # Get the default factory generator for the given table
      def get_factory_generator(table_name)
        @factory_generators[table_name.to_s] || ::RGeo::ActiveRecord::DEFAULT_FACTORY_GENERATOR
      end

      # Set the default factory generator for the given table
      def set_factory_generator(table_name, generator)
        @factory_generators[table_name.to_s] = generator
      end

      # Get the factory or factory generator for the given table name and column name.
      def get_column_factory(table_name, column_name, params = {})
        table_name = table_name.to_s
        column_name = column_name.to_s
        result = (@column_factories[table_name] ||= {})[column_name] ||
          @factory_generators[table_name] || ::RGeo::ActiveRecord::DEFAULT_FACTORY_GENERATOR
        if !result.kind_of?(::RGeo::Feature::Factory::Instance)
          result = result.call(params)
        end
        result
      end

      # Set the factory or factory generator for the given table name and column name.
      def set_column_factory(table_name, column_name, factory)
        (@column_factories[table_name.to_s] ||= {})[column_name.to_s] = factory
      end

      # Clear settings for the given table name, or for all tables
      def clear!(table_name = nil)
        if table_name
          table_name = table_name.to_s
          @factory_generators.delete(table_name)
          @column_factories.delete(table_name)
        else
          @factory_generators.clear
          @column_factories.clear
        end
      end

      DEFAULT = self.new
    end

    # Additional class methods on ::ActiveRecord::Base that provide
    # a way to control the RGeo factory used for ActiveRecord objects.
    module ActiveRecordBaseFactorySettings
      # Return the RGeoFactorySettings object associated with this class's connection.
      def rgeo_factory_settings
        pool = begin
          connection_pool
        rescue ::ActiveRecord::ConnectionNotEstablished
          nil
        end
        pool ? pool.rgeo_factory_settings : RGeoFactorySettings::DEFAULT
      end

      # The value of this attribute is a RGeo::Feature::FactoryGenerator
      # that is used to generate the proper factory when loading geometry
      # objects from the database. For example, if the data being loaded
      # has M but not Z coordinates, and an embedded SRID, then this
      # FactoryGenerator is called with the appropriate configuration to
      # obtain a factory with those properties. This factory is the one
      # associated with the actual geometry properties of the ActiveRecord
      # object. The result of this generator can be overridden by setting
      # an explicit factory for a given class and column using the
      # column_rgeo_factory method.

      def rgeo_factory_generator
        rgeo_factory_settings.get_factory_generator(table_name)
      end

      # Set the rgeo_factory_generator attribute
      def rgeo_factory_generator=(generator)
        rgeo_factory_settings.set_factory_generator(table_name, generator)
      end

      # This is a convenient way to set the rgeo_factory_generator by
      # passing a block.
      def to_generate_rgeo_factory(&block)
        rgeo_factory_settings.set_factory_generator(table_name, block)
      end

      # Set a specific factory for this ActiveRecord class and the given
      # column name. This setting, if present, overrides the result of the
      # rgeo_factory_generator.
      def set_rgeo_factory_for_column(column_name, factory)
        rgeo_factory_settings.set_column_factory(table_name, column_name, factory)
      end

      # Returns the factory generator or specific factory to use for this
      # ActiveRecord class and the given column name.
      # If an explicit factory was set for the given column, returns it.
      # Otherwise, if a params hash is given, passes that hash to the
      # rgeo_factory_generator for this class, and returns the resulting
      # factory. Otherwise, if no params hash is given, just returns the
      # rgeo_factory_generator for this class.
      def rgeo_factory_for_column(column_name, params = {})
        rgeo_factory_settings.get_column_factory(table_name, column_name, params)
      end
    end

    ::ActiveRecord::Base.extend(ActiveRecordBaseFactorySettings)

    # :stopdoc:

    # Patch for connection pool to track geo factories per table name
    ::ActiveRecord::ConnectionAdapters::ConnectionPool.class_eval do
      def rgeo_factory_settings
        @_rgeo_factory_settings ||= RGeoFactorySettings.new
      end

      private

      alias_method :new_connection_without_rgeo_modification, :new_connection
      def new_connection
        result = new_connection_without_rgeo_modification
        if result.respond_to?(:set_rgeo_factory_settings)
          result.set_rgeo_factory_settings(rgeo_factory_settings)
        end
        result
      end
    end

    # :startdoc:

  end
end
