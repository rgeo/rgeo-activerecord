module RGeo
  module ActiveRecord
    # Some default column constructors specifications for most spatial
    # databases. Individual adapters may add to or override this list.
    DEFAULT_SPATIAL_COLUMN_CONSTRUCTORS = {
      geometry_collection: {}.freeze,
      geometry:            {}.freeze,
      line_string:         {}.freeze,
      multi_line_string:   {}.freeze,
      multi_point:         {}.freeze,
      multi_polygon:       {}.freeze,
      point:               {}.freeze,
      polygon:             {}.freeze,
      spatial:             { type: "geometry" }.freeze,
    }.freeze

    # Index definition struct with a spatial flag field.

    SpatialIndexDefinition = Struct.new(:table, :name, :unique, :columns, :lengths, :orders, :where, :spatial)

    # Returns a feature type module given a string type.

    def self.geometric_type_from_name(name)
      case name.to_s
      when /^geometrycollection/i then Feature::GeometryCollection
      when /^geometry/i then Feature::Geometry
      when /^linestring/i then Feature::LineString
      when /^multilinestring/i then Feature::MultiLineString
      when /^multipoint/i then Feature::MultiPoint
      when /^multipolygon/i then Feature::MultiPolygon
      when /^point/i then Feature::Point
      when /^polygon/i then Feature::Polygon
      end
    end
  end
end
