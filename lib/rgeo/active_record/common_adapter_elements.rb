# autoload AbstractAdapter
ActiveRecord::ConnectionAdapters::AbstractAdapter

module RGeo
  module ActiveRecord
    # Some default column constructors specifications for most spatial
    # databases. Individual adapters may add to or override this list.
    DEFAULT_SPATIAL_COLUMN_CONSTRUCTORS = {
      spatial:             { type: "geometry" }.freeze,
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

    SpatialIndexDefinition = Struct.new(:table, :name, :unique, :columns, :lengths, :orders, :where, :spatial)

    # Returns a feature type module given a string type.

    def self.geometric_type_from_name(name)
      case name.to_s
      when /^geometry/i then RGeo::Feature::Geometry
      when /^point/i then RGeo::Feature::Point
      when /^linestring/i then RGeo::Feature::LineString
      when /^polygon/i then RGeo::Feature::Polygon
      when /^geometrycollection/i then RGeo::Feature::GeometryCollection
      when /^multipoint/i then RGeo::Feature::MultiPoint
      when /^multilinestring/i then RGeo::Feature::MultiLineString
      when /^multipolygon/i then RGeo::Feature::MultiPolygon
      end
    end
  end
end
