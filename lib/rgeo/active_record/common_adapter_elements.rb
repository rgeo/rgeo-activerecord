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


require 'active_record'

::ActiveRecord::ConnectionAdapters::AbstractAdapter


module RGeo
  
  module ActiveRecord
    
    
    # Some default column constructors specifications for most spatial
    # databases. Individual adapters may add to or override this list.
    
    DEFAULT_SPATIAL_COLUMN_CONSTRUCTORS = {
      :spatial => {:type => 'geometry'}.freeze,
      :geometry => {}.freeze,
      :point => {}.freeze,
      :line_string => {}.freeze,
      :polygon => {}.freeze,
      :geometry_collection => {}.freeze,
      :multi_line_string => {}.freeze,
      :multi_point => {}.freeze,
      :multi_polygon => {}.freeze,
    }.freeze
    
    
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
    
    
    # :stopdoc:
    
    
    # Provide methods for each geometric subtype during table definitions.
    
    ::ActiveRecord::ConnectionAdapters::TableDefinition.class_eval do
      alias_method :method_missing_without_rgeo_modification, :method_missing
      def method_missing(method_name_, *args_, &block_)
        if @base.respond_to?(:spatial_column_constructor) && (info_ = @base.spatial_column_constructor(method_name_))
          info_ = info_.dup
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
    
    
    # Provide methods for each geometric subtype during table changes.
    
    ::ActiveRecord::ConnectionAdapters::Table.class_eval do
      alias_method :method_missing_without_rgeo_modification, :method_missing
      def method_missing(method_name_, *args_, &block_)
        if @base.respond_to?(:spatial_column_constructor) && (info_ = @base.spatial_column_constructor(method_name_))
          info_ = info_.dup
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
    
    
    # Hack schema dumper to output spatial index flag
    
    ::ActiveRecord::SchemaDumper.class_eval do
      private
      def indexes(table_, stream_)
        if (indexes_ = @connection.indexes(table_)).any?
          add_index_statements_ = indexes_.map do |index_|
            statement_parts_ = [
              ('add_index ' + index_.table.inspect),
              index_.columns.inspect,
              (':name => ' + index_.name.inspect),
            ]
            statement_parts_ << ':unique => true' if index_.unique
            statement_parts_ << ':spatial => true' if index_.respond_to?(:spatial) && index_.spatial
            index_lengths_ = (index_.lengths || []).compact
            statement_parts_ << (':length => ' + ::Hash[*index_.columns.zip(index_.lengths).flatten].inspect) unless index_lengths_.empty?
            '  ' + statement_parts_.join(', ')
          end
          stream_.puts add_index_statements_.sort.join("\n")
          stream_.puts
        end
      end
    end
    
    
    # Tell ActiveRecord to cache spatial attribute values so they don't get
    # re-parsed on every access.
    
    ::ActiveRecord::Base.attribute_types_cached_by_default << :spatial
    
    
    # :startdoc:
    
    
  end
  
end
