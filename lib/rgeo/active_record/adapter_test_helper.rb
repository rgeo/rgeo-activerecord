# -----------------------------------------------------------------------------
#
# Helper methods for ActiveRecord adapter tests
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

require 'rgeo/active_record'
require 'yaml'
require 'logger'


module RGeo
  module ActiveRecord


    # A helper module for creating unit tests for adapters.

    module AdapterTestHelper

      @class_num = 0


      # When this module is included in a test case class, it
      # automatically attempts to load the database config file from the
      # path specified by constants defined in the class. It first tries
      # OVERRIDE_DATABASE_CONFIG_PATH, and then falls back on
      # DATABASE_CONFIG_PATH.
      # It then defines the DATABASE_CONFIG and DEFAULT_AR_CLASS constants
      # in the testcase class.
      #
      # When you define your test methods, you should wrap them in a call
      # to the class method define_test_methods. This will cause them to
      # be defined conditionally based on whether the database config is
      # present.

      def self.included(klass_)
        database_config_ = ::YAML.load_file(klass_.const_get(:OVERRIDE_DATABASE_CONFIG_PATH)) rescue nil
        database_config_ ||= ::YAML.load_file(klass_.const_get(:DATABASE_CONFIG_PATH)) rescue nil
        if database_config_
          database_config_.stringify_keys!
          if klass_.respond_to?(:before_open_database)
            klass_.before_open_database(:config => database_config_)
          end
          klass_.const_set(:DATABASE_CONFIG, database_config_)
          ar_class_ = AdapterTestHelper.new_class(database_config_)
          klass_.const_set(:DEFAULT_AR_CLASS, ar_class_)
          if klass_.respond_to?(:initialize_database)
            klass_.initialize_database(:ar_class => ar_class_, :connection => ar_class_.connection)
          end
          def klass_.define_test_methods
            yield
          end
        else
          def klass_.define_test_methods
            def test_warning
              puts "WARNING: Couldn't find database.yml; skipping tests."
            end
          end
        end
      end


      def self.new_class(param_)  # :nodoc:
        base_ = param_.kind_of?(::Class) ? param_ : ::ActiveRecord::Base
        config_ = param_.kind_of?(::Hash) ? param_ : nil
        klass_ = ::Class.new(base_)
        @class_num += 1
        self.const_set("Klass#{@class_num}".to_sym, klass_)
        klass_.class_eval do
          establish_connection(config_) if config_
          self.table_name = :spatial_test
        end
        klass_
      end


      # Default setup method that calls cleanup_tables.
      # It also defines a couple of useful factories: @factory (a
      # cartesian factory) and @geographic_factory (a spherical factory)

      def setup
        @factory = ::RGeo::Cartesian.preferred_factory(:srid => 3785)
        @geographic_factory = ::RGeo::Geographic.spherical_factory(:srid => 4326)
        cleanup_tables
        cleanup_caches
      end


      # Default teardown method that calls cleanup_tables.

      def teardown
        cleanup_tables
        cleanup_caches
      end


      # Utility method that attempts to clean up any table that was
      # created by a test method. Normally called automatically at setup
      # and teardown. If you override those methods, you'll need to call
      # this from your method.

      def cleanup_tables
        klass_ = self.class.const_get(:DEFAULT_AR_CLASS)
        if klass_.connection.tables.include?('spatial_test')
          klass_.connection.drop_table(:spatial_test)
        end
      end


      # Utility method that cleans up any schema info that was cached by
      # ActiveRecord during a test. Normally called automatically at setup
      # and teardown. If you override those methods, you'll need to call
      # this from your method.

      def cleanup_caches
        klass_ = self.class.const_get(:DEFAULT_AR_CLASS)

        # Clear any RGeo factory settings.
        klass_.connection_pool.rgeo_factory_settings.clear!

        # Clear out any ActiveRecord caches that are present.
        # Different Rails versions use different types of caches.
        has_schema_cache_ = false
        klass_.connection_pool.with_connection do |c_|
          if c_.respond_to?(:schema_cache)
            # 3.2.x and 4.0.x
            c_.schema_cache.clear!
            has_schema_cache_ = true
          end
          if c_.respond_to?(:clear_cache!)
            # 3.1 and above
            c_.clear_cache!
          end
          # All 3.x and 4.0
          c_.clear_query_cache
        end
        if !has_schema_cache_ && klass_.connection_pool.respond_to?(:clear_cache!)
          # 3.1.x only
          klass_.connection_pool.clear_cache!
        end
      end


      # Utility method that creates and returns a new ActiveRecord class
      # subclassing the DEFAULT_AR_CLASS.

      def create_ar_class(opts_={})
        @ar_class = AdapterTestHelper.new_class(self.class.const_get(:DEFAULT_AR_CLASS))
      end


    end


  end
end
