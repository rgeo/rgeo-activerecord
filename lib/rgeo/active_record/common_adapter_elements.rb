# autoload AbstractAdapter
::ActiveRecord::ConnectionAdapters::AbstractAdapter

module RGeo
  module ActiveRecord
    # Some default column constructors specifications for most spatial
    # databases. Individual adapters may add to or override this list.
    DEFAULT_SPATIAL_COLUMN_CONSTRUCTORS = {
      spatial:             { :type => 'geometry' }.freeze,
      geometry:            {}.freeze,
      point:               {}.freeze,
      line_string:         {}.freeze,
      polygon:             {}.freeze,
      geometry_collection: {}.freeze,
      multi_line_string:   {}.freeze,
      multi_point:         {}.freeze,
      multi_polygon:       {}.freeze,
    }.freeze

    # Index definition struct with a spatial flag field.

    class SpatialIndexDefinition < Struct.new(:table, :name, :unique, :columns, :lengths, :orders, :where, :spatial)
    end

    # Returns a feature type module given a string type.

    def self.geometric_type_from_name(name)
      case name.to_s
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

      def method_missing_with_rgeo(method_name, *args, &block)
        if @base.respond_to?(:spatial_column_constructor) && (info = @base.spatial_column_constructor(method_name))
          info = info.dup
          type = (info.delete(:type) || method_name).to_s
          opts = args.extract_options!.merge(info)
          args.each do |name|
            column(name, type, opts)
          end
        else
          method_missing_without_rgeo(method_name, *args, &block)
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

      def method_missing_with_rgeo(method_name, *args, &block)
        if @base.respond_to?(:spatial_column_construcor) && (info = @base.spatial_column_constructor(method_name))
          info = info.dup
          type = (info.delete(:type) || method_name).to_s
          opts = args.extract_options!.merge(info)
          args.each do |name|
            @base.add_column(@table_name, name, type, opts)
          end
        else
          method_missing_without_rgeo(method_name, *args, &block)
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

      def indexes_with_rgeo(table, stream)
        indexes = @connection.indexes(table)
        if indexes.any?
          add_index_statements = indexes.map do |index|
            statement_parts_ = [
                ("add_index #{index.table.inspect}"),
                index.columns.inspect,
                ("name: #{index.name.inspect}"),
              ]
            statement_parts_ << 'unique: true' if index.unique
            statement_parts_ << 'spatial: true' if index.respond_to?(:spatial) && index.spatial
            index_lengths = (index.lengths || []).compact
            statement_parts_ << ("length: #{::Hash[*index.columns.zip(index.lengths).flatten].inspect}") if index_lengths.any?
            "  #{statement_parts_.join(', ')}"
          end
          stream.puts add_index_statements.sort.join("\n")
          stream.puts
        end
      end
    end

    ::ActiveRecord::SchemaDumper.send :include, GeoSchemaDumper


    # attribute_types_cached_by_default was removed in ActiveRecord 4.2
    # :cache_attributes does not work since the connection may not yet be established

    if ::ActiveRecord.version < Gem::Version.new("4.2.0.a")
      # cache spatial attribute values so they don't get re-parsed on every access.
      ::ActiveRecord::Base.attribute_types_cached_by_default << :spatial
    end

    # :startdoc:
  end
end
