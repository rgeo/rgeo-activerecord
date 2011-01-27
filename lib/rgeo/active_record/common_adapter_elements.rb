# -----------------------------------------------------------------------------
# 
# Common tools for spatial adapters for ActiveRecord
# 
# -----------------------------------------------------------------------------
# Copyright 2010 Daniel Azuma
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
;


module RGeo
  
  module ActiveRecord
    
    
    # Additional column types for geometries. (DEPRECATED)
    GEOMETRY_TYPES = [:geometry, :point, :line_string, :polygon, :geometry_collection, :multi_line_string, :multi_point, :multi_polygon].freeze
    
    
    DEFAULT_SPATIAL_COLUMN_CONSTRUCTORS = {
      :spatial => {:type => 'geometry'},
      :geometry => {},
      :point => {},
      :line_string => {},
      :polygon => {},
      :geometry_collection => {},
      :multi_line_string => {},
      :multi_point => {},
      :multi_polygon => {},
    }.freeze
        
    
    # The default factory generator for ActiveRecord::Base.
    DEFAULT_FACTORY_GENERATOR = ::Proc.new do |config_|
      if config_.delete(:geographic)
        ::RGeo::Geographic.spherical_factory(config_)
      else
        ::RGeo::Cartesian.preferred_factory(config_)
      end
    end
    
    
    # Index definition struct with a spatial flag field.
    
    class SpatialIndexDefinition < ::Struct.new(:table, :name, :unique, :columns, :lengths, :spatial)
    end
    
    
    # Returns a feature type module given a string type.
    
    def self.geometric_type_from_name(name_)
      case name_.to_s
      when /^geometry/i then ::RGeo::Feature::Geometry
      when /^point/i then ::RGeo::Feature::Point
      when /^linestring/i then ::RGeo::Feature::LineString
      when /^polygon/i then ::RGeo::Feature::Polygon
      when /^geometrycollection/i then ::RGeo::Feature::GeometryCollection
      when /^multipoint/i then ::RGeo::Feature::MultiPoint
      when /^multilinestring/i then ::RGeo::Feature::MultiLineString
      when /^multipolygon/i then ::RGeo::Feature::MultiPolygon
      else nil
      end
    end
    
    
  end
  
end


# :stopdoc:


# Make sure a few things are autoloaded.
::Arel::Attributes
::ActiveRecord::ConnectionAdapters::AbstractAdapter
::ActiveRecord::ConnectionAdapters::TableDefinition
::ActiveRecord::ConnectionAdapters::Table
::ActiveRecord::Base
::ActiveRecord::SchemaDumper


# Hack Arel Attributes dispatcher to recognize geometry columns.
# This is deprecated but necessary to support legacy Arel versions.

module Arel
  module Attributes
    class << self
      if method_defined?(:for)
        alias_method :for_without_rgeo_modification, :for
        def for(column_)
          column_.type == :spatial ? Attribute : for_without_rgeo_modification(column_)
        end
      end
    end
  end
end


# Provide methods for each geometric subtype during table definitions.

module ActiveRecord
  module ConnectionAdapters
    class TableDefinition
      
      alias_method :method_missing_without_rgeo_modification, :method_missing
      def method_missing(method_name_, *args_, &block_)
        if @base.respond_to?(:spatial_column_constructor) && (info_ = @base.spatial_column_constructor(method_name_))
          type_ = (info_.delete(:type) || method_name_).to_s
          opts_ = args_.extract_options!.merge(info_)
          args_.each do |name_|
            column(name_, type_, opts_)
          end
        else
          method_missing_without_rgeo_modification(method_name_, *args_, &block_)
        end
      end
      
    end
  end
end


module ActiveRecord
  module ConnectionAdapters
    class Table
      
      alias_method :method_missing_without_rgeo_modification, :method_missing
      def method_missing(method_name_, *args_, &block_)
        if @base.respond_to?(:spatial_column_constructor) && (info_ = @base.spatial_column_constructor(method_name_))
          type_ = (info_.delete(:type) || method_name_).to_s
          opts_ = args_.extract_options!.merge(info_)
          args_.each do |name_|
            @base.add_column(@table_name, name_, type_, opts_)
          end
        else
          method_missing_without_rgeo_modification(method_name_, *args_, &block_)
        end
      end
      
    end
  end
end


# When creating column objects, cause the enclosing ActiveRecord class
# to be set on any column that recognizes it. This is commonly used by
# spatial column subclasses.

module ActiveRecord
  class Base
    class << self
      alias_method :columns_without_rgeo_modification, :columns
      def columns
        unless defined?(@columns) && @columns
          columns_without_rgeo_modification.each do |column_|
            column_.set_ar_class(self) if column_.respond_to?(:set_ar_class)
          end
        end
        @columns
      end
    end
  end
end


# Hack schema dumper to output spatial index flag

module ActiveRecord
  class SchemaDumper
    private
    def indexes(table_, stream_)
      if (indexes_ = @connection.indexes(table_)).any?
        add_index_statements_ = indexes_.map do |index_|
          statement_parts_ = [ ('add_index ' + index_.table.inspect) ]
          statement_parts_ << index_.columns.inspect
          statement_parts_ << (':name => ' + index_.name.inspect)
          statement_parts_ << ':unique => true' if index_.unique
          statement_parts_ << ':spatial => true' if index_.respond_to?(:spatial) && index_.spatial
          index_lengths_ = index_.lengths.compact if index_.lengths.is_a?(::Array)
          statement_parts_ << (':length => ' + ::Hash[*index_.columns.zip(index_.lengths).flatten].inspect) if index_lengths_.present?
          '  ' + statement_parts_.join(', ')
        end
        stream_.puts add_index_statements_.sort.join("\n")
        stream_.puts
      end
    end
  end
end


# Tell ActiveRecord to cache spatial attribute values so they don't get
# re-parsed on every access.

::ActiveRecord::Base.attribute_types_cached_by_default << :spatial


# :startdoc:
