require "test_helper"

class BasicTest < Minitest::Test
  def test_version
    assert RGeo::ActiveRecord::VERSION
  end

  def test_json_generator_wkt
    setup_wkt
    assert_equal "POINT (1.0 2.0)", cartesian_factory.point(1, 2).as_json
  end

  def test_json_generator_geojson
    RGeo::ActiveRecord::GeometryMixin.set_json_generator(:geojson)
    point = cartesian_factory.point(1, 2)
    assert_equal({ "type" => "Point", "coordinates" => [1.0, 2.0] }, point.as_json)
  end

  def test_as_json_spherical_line
    setup_wkt
    line = spherical_factory.line(spherical_factory.point(1, 2), spherical_factory.point(3, 4))
    assert_equal "LINESTRING (1.0 2.0, 3.0 4.0)", line.as_json
  end

  def test_as_json_projected_polygon
    setup_wkt
    points = [[0, 0], [0, 1], [1, 1], [1, 0]].map { |x, y| mercator_factory.point(x, y) }
    polygon = mercator_factory.polygon(mercator_factory.linear_ring(points))
    assert_equal "POLYGON ((0.0 0.0, 0.0 1.0, 1.0 1.0, 1.0 0.0, 0.0 0.0))", polygon.as_json
  end

  def test_as_json_ffi_line_string
    setup_wkt
    line_string = ffi_factory.line(ffi_factory.point(1, 2), ffi_factory.point(3, 4))
    assert_equal "LINESTRING (1.0 2.0, 3.0 4.0)", line_string.as_json
  end

  def test_as_json_zm_point
    setup_wkt
    assert_equal "POINT (1.0 2.0 3.0 4.0)", zm_factory.point(1, 2, 3, 4).as_json
  end

  def test_arel_visit_spatial_constant_node
    visitor = arel_visitor
    sql = visitor.accept(Arel.spatial("POINT (1.0 2.0)"), Arel::Collectors::PlainString.new)
    assert_equal("ST_WKTToSQL('POINT (1.0 2.0)')", sql.value)
  end

  private

  def arel_visitor
    Arel::Visitors::PostgreSQL.new(FakeRecord::Connection.new)
  end

  def setup_wkt
    RGeo::ActiveRecord::GeometryMixin.set_json_generator(nil)
  end

  # builds Geos::CAPI* features
  def cartesian_factory
    RGeo::Cartesian.preferred_factory
  end

  # builds Geographic::Projected* features
  def mercator_factory
    RGeo::Geographic.simple_mercator_factory
  end

  # builds Geographic::Spherical* features
  def spherical_factory
    RGeo::Geographic.spherical_factory
  end

  # builds Geos::FFI* features
  def ffi_factory
    RGeo::Geos.factory(native_interface: :ffi)
  end

  # builds Geos::ZM* features
  def zm_factory
    RGeo::Geos.factory(has_z_coordinate: true, has_m_coordinate: true)
  end
end
