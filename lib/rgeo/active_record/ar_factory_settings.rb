# -----------------------------------------------------------------------------
#
# Additions to ActiveRecord::Base for factory settings
#
# -----------------------------------------------------------------------------
# Copyright 2010-2012 Daniel Azuma
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the copyright holder, nor the names of any other
#   contributors to this software, may be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------

module RGeo
  module ActiveRecord
    # The default factory generator for ActiveRecord::Base.

    DEFAULT_FACTORY_GENERATOR = ::Proc.new do |config_|
      if config_.delete(:geographic)
        ::RGeo::Geographic.spherical_factory(config_)
      else
        ::RGeo::Cartesian.preferred_factory(config_)
      end
    end

    # An object that manages the RGeo factories for a ConnectionPool.
    class RGeoFactorySettings

      def initialize  # :nodoc:
        @factory_generators = {}
        @column_factories = {}
      end

      # Get the default factory generator for the given table
      def get_factory_generator(table_name_)
        @factory_generators[table_name_.to_s] || ::RGeo::ActiveRecord::DEFAULT_FACTORY_GENERATOR
      end

      # Set the default factory generator for the given table
      def set_factory_generator(table_name_, gen_)
        @factory_generators[table_name_.to_s] = gen_
      end

      # Get the factory or factory generator for the given table name
      # and column name.
      def get_column_factory(table_name_, column_name_, params_=nil)
        table_name_ = table_name_.to_s
        column_name_ = column_name_.to_s
        result_ = (@column_factories[table_name_] ||= {})[column_name_] ||
          @factory_generators[table_name_] || ::RGeo::ActiveRecord::DEFAULT_FACTORY_GENERATOR
        if params_ && !result_.kind_of?(::RGeo::Feature::Factory::Instance)
          result_ = result_.call(params_)
        end
        result_
      end

      # Set the factory or factory generator for the given table name
      # and column name.
      def set_column_factory(table_name_, column_name_, factory_)
        (@column_factories[table_name_.to_s] ||= {})[column_name_.to_s] = factory_
      end

      # Clear settings for the given table name, or for all tables
      def clear!(table_name_=nil)
        if table_name_
          table_name_ = table_name_.to_s
          @factory_generators.delete(table_name_)
          @column_factories.delete(table_name_)
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
      # Return the RGeoFactorySettings object associated with this
      # class's connection.
      def rgeo_factory_settings
        pool_ = begin
          connection_pool
        rescue ::ActiveRecord::ConnectionNotEstablished
          nil
        end
        pool_ ? pool_.rgeo_factory_settings : RGeoFactorySettings::DEFAULT
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
      def rgeo_factory_generator=(gen_)
        rgeo_factory_settings.set_factory_generator(table_name, gen_)
      end

      # This is a convenient way to set the rgeo_factory_generator by
      # passing a block.
      def to_generate_rgeo_factory(&block_)
        rgeo_factory_settings.set_factory_generator(table_name, block_)
      end

      # Set a specific factory for this ActiveRecord class and the given
      # column name. This setting, if present, overrides the result of the
      # rgeo_factory_generator.
      def set_rgeo_factory_for_column(column_name_, factory_)
        rgeo_factory_settings.set_column_factory(table_name, column_name_, factory_)
      end

      # Returns the factory generator or specific factory to use for this
      # ActiveRecord class and the given column name.
      # If an explicit factory was set for the given column, returns it.
      # Otherwise, if a params hash is given, passes that hash to the
      # rgeo_factory_generator for this class, and returns the resulting
      # factory. Otherwise, if no params hash is given, just returns the
      # rgeo_factory_generator for this class.
      def rgeo_factory_for_column(column_name_, params_=nil)
        rgeo_factory_settings.get_column_factory(table_name, column_name_, params_)
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
        result_ = new_connection_without_rgeo_modification
        if result_.respond_to?(:set_rgeo_factory_settings)
          result_.set_rgeo_factory_settings(rgeo_factory_settings)
        end
        result_
      end
    end

    # :startdoc:

  end
end
