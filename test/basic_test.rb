# frozen_string_literal: true

require "test_helper"

class BasicTest < Minitest::Test
  def test_version
    assert RGeo::ActiveRecord::VERSION
  end

  if RGeo::Geos.capi_supported?
    def test_as_json_geos_api
      setup_wkt
      assert_equal "POINT (1.0 2.0)", geos_capi_factory.point(1, 2).as_json
    end
  end

  def test_as_json_cartesian
    setup_wkt
    assert_equal "POINT (1.0 2.0)", cartesian_factory.point(1, 2).as_json
  end

  def test_json_generator_geojson
    RGeo::ActiveRecord::GeometryMixin.set_json_generator(:geojson)
    point = spherical_factory.point(1, 2)
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

  if RGeo::Geos.ffi_supported?
    def test_as_json_ffi_line_string
      setup_wkt
      line_string = ffi_factory.line(ffi_factory.point(1, 2), ffi_factory.point(3, 4))
      assert_equal "LINESTRING (1.0 2.0, 3.0 4.0)", line_string.as_json
    end
  end

  def test_as_json_zm_point
    setup_wkt
    assert_equal "POINT (1.0 2.0 3.0 4.0)", zm_factory.point(1, 2, 3, 4).as_json
  end

  def test_arel_visit_spatial_constant_node
    visitor = arel_visitor
    sql = visitor.accept(Arel.spatial("POINT (1.0 2.0)"), Arel::Collectors::PlainString.new)
    assert_equal("ST_GeomFromText('POINT (1.0 2.0)')", sql.value)
  end

  def test_spatial_expressions
    func = RGeo::ActiveRecord::SpatialNamedFunction.new("SPATIAL_FUNC", ["POINT(1 2)", "POINT(1 2)"], [false, true, true])
    assert_equal(func.spatial_result?, false)
    assert_equal(func.spatial_argument?(0), true)
    assert_equal(func.spatial_argument?(1), true)

    func = RGeo::ActiveRecord::SpatialNamedFunction.new("SPATIAL_FUNC", ["POINT(1 2)", 10], [true, true, false])
    assert_equal(func.spatial_result?, true)
    assert_equal(func.spatial_argument?(0), true)
    assert_equal(func.spatial_argument?(1), false)
  end

  def test_arel_visit_RGeo_ActiveRecord_SpatialNamedFunction_string
    visitor = arel_visitor
    named_func = RGeo::ActiveRecord::SpatialNamedFunction.new("SPATIAL_FUNC",
                                                              ["POINT (1.0 2.0)",
                                                               "LINESTRING (1.0 2.0, 2.0 3.0)"],
                                                              [false, true, true])
    sql = visitor.accept(named_func, Arel::Collectors::PlainString.new)
    assert_equal("SPATIAL_FUNC(ST_GeomFromText('POINT (1.0 2.0)'), ST_GeomFromText('LINESTRING (1.0 2.0, 2.0 3.0)'))", sql.value)
  end

  def test_arel_visit_RGeo_ActiveRecord_SpatialNamedFunction_feature
    visitor = arel_visitor
    pt1 = geos_capi_factory.point(1, 2)
    pt2 = geos_capi_factory.point(2, 3)
    line = geos_capi_factory.line_string([pt1, pt2])
    named_func = RGeo::ActiveRecord::SpatialNamedFunction.new("SPATIAL_FUNC", [pt1, line], [false, true, true])
    sql = visitor.accept(named_func, Arel::Collectors::PlainString.new)
    assert_equal("SPATIAL_FUNC(ST_GeomFromText('POINT (1.0 2.0)', 0), ST_GeomFromText('LINESTRING (1.0 2.0, 2.0 3.0)', 0))", sql.value)
  end

  def test_arel_visit_RGeo_ActiveRecord_SpatialNamedFunction_bbox
    visitor = arel_visitor
    merc_factory = RGeo::Geos.factory(srid: 3857, wkt_generator: ruby_wkt_generator_opts)
    pt1 = merc_factory.point(1, 2)
    pt2 = merc_factory.point(2, 3)
    bbox = RGeo::Cartesian::BoundingBox.create_from_points(pt1, pt2)
    named_func = RGeo::ActiveRecord::SpatialNamedFunction.new("SPATIAL_FUNC", [bbox], [false, true])
    sql = visitor.accept(named_func, Arel::Collectors::PlainString.new)
    assert_equal("SPATIAL_FUNC(ST_GeomFromText('POLYGON ((1.0 2.0, 2.0 2.0, 2.0 3.0, 1.0 3.0, 1.0 2.0))', 3857))", sql.value)
  end

  def test_arel_visit_RGeo_ActiveRecord_SpatialNamedFunction_with_alias
    visitor = arel_visitor
    table = Arel::Table.new("spatial_models")

    geo_factory = RGeo::Geographic.spherical_factory(srid: 4326)
    pt = geo_factory.point(1, 1)

    stmt = table.project(Arel.star, table[:lonlat].st_distance(Arel.spatial(pt)).as("distance"))
    sql = visitor.accept(stmt, Arel::Collectors::SQLString.new)

    assert_equal("(SELECT *, ST_Distance(\"spatial_models\".\"lonlat\", ST_GeomFromText('POINT (1.0 1.0)', 4326)) AS distance FROM \"spatial_models\")", sql.value)
  end

  def test_arel_visit_RGeo_ActiveRecord_SpatialNamedFunction_with_distinct
    visitor = arel_visitor
    named_func = RGeo::ActiveRecord::SpatialNamedFunction.new("SPATIAL_FUNC",
                                                              ["POINT (1.0 2.0)",
                                                               "LINESTRING (1.0 2.0, 2.0 3.0)"],
                                                              [false, true, true])
    named_func.distinct = true
    sql = visitor.accept(named_func, Arel::Collectors::PlainString.new)
    assert_equal("SPATIAL_FUNC(DISTINCT ST_GeomFromText('POINT (1.0 2.0)'), ST_GeomFromText('LINESTRING (1.0 2.0, 2.0 3.0)'))", sql.value)
  end

  private

  def arel_visitor
    conn = FakeRecord::Base.new
    Arel::Visitors::ToSql.new(conn.connection)
  end

  def setup_wkt
    RGeo::ActiveRecord::GeometryMixin.set_json_generator(nil)
  end

  def ruby_wkt_generator_opts
    {
      convert_case: :upper
    }
  end

  # builds Geos::CAPI* features
  def geos_capi_factory
    RGeo::Cartesian.preferred_factory(
      wkt_generator: ruby_wkt_generator_opts
    )
  end

  # builds Cartesian::* features
  def cartesian_factory
    RGeo::Cartesian.simple_factory
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
    RGeo::Geos.factory(native_interface: :ffi, wkt_generator: ruby_wkt_generator_opts)
  end

  # builds Geos::ZM* features
  def zm_factory
    RGeo::Geos.factory(has_z_coordinate: true, has_m_coordinate: true)
  end
end
