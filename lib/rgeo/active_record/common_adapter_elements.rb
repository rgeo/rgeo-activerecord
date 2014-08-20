# autoload AbstractAdapter
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

    class SpatialIndexDefinition < Struct.new(:table, :name, :unique, :columns, :lengths, :orders, :where, :spatial)
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
    module GeoTableDefinitions
      def self.included(base)
        base.class_eval do
          alias_method :method_missing_without_rgeo, :method_missing
          alias_method :method_missing, :method_missing_with_rgeo
        end
      end

      def method_missing_with_rgeo(method_name_, *args_, &block_)
        if @base.respond_to?(:spatial_column_constructor) && (info_ = @base.spatial_column_constructor(method_name_))
          info_ = info_.dup
          type_ = (info_.delete(:type) || method_name_).to_s
          opts_ = args_.extract_options!.merge(info_)
          args_.each do |name_|
            column(name_, type_, opts_)
          end
        else
          method_missing_without_rgeo(method_name_, *args_, &block_)
        end
      end
    end

    ::ActiveRecord::ConnectionAdapters::TableDefinition.send :include, GeoTableDefinitions


    # Provide methods for each geometric subtype during table changes.
    module GeoConnectionAdapters
      def self.included(base)
        base.class_eval do
          alias_method :method_missing_without_rgeo, :method_missing
          alias_method :method_missing, :method_missing_with_rgeo
        end
      end

      def method_missing_with_rgeo(method_name_, *args_, &block_)
        if @base.respond_to?(:spatial_column_constructor) && (info_ = @base.spatial_column_constructor(method_name_))
          info_ = info_.dup
          type_ = (info_.delete(:type) || method_name_).to_s
          opts_ = args_.extract_options!.merge(info_)
          args_.each do |name_|
            @base.add_column(@table_name, name_, type_, opts_)
          end
        else
          method_missing_without_rgeo(method_name_, *args_, &block_)
        end
      end
    end

    ::ActiveRecord::ConnectionAdapters::Table.send :include, GeoConnectionAdapters


    # Hack schema dumper to output spatial index flag
    module GeoSchemaDumper
      def self.included(base)
        base.class_eval do
          alias_method :indexes_without_rgeo, :indexes
          alias_method :indexes, :indexes_with_rgeo
        end
      end

      private

      def indexes_with_rgeo(table_, stream_)
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

    ::ActiveRecord::SchemaDumper.send :include, GeoSchemaDumper


    # Tell ActiveRecord to cache spatial attribute values so they don't get re-parsed on every access.
    ::ActiveRecord::Base.cache_attributes(:spatial)

    # :startdoc:
  end
end
