require 'test_helper'

class BasicTest < Minitest::Test
  class MyTable < ActiveRecord::Base
  end

  def test_version
    assert RGeo::ActiveRecord::VERSION
  end

  def test_default_as_json_wkt
    RGeo::ActiveRecord::GeometryMixin.set_json_generator(nil)
    factory = RGeo::Cartesian.preferred_factory
    point = factory.point(1, 2)
    assert_equal "POINT (1.0 2.0)", point.as_json
  end

  def test_default_as_json_geojson
    RGeo::ActiveRecord::GeometryMixin.set_json_generator(:geojson)
    factory = RGeo::Cartesian.preferred_factory
    point = factory.point(1, 2)
    assert_equal({ 'type' => 'Point', 'coordinates' => [1.0, 2.0] }, point.as_json)
  end

  def test_arel_visit_spatial_constant_node
    visitor = arel_visitor
    sql = visitor.accept(Arel.spatial('POINT (1.0 2.0)'), Arel::Collectors::PlainString.new)
    assert_equal("ST_WKTToSQL('POINT (1.0 2.0)')", sql.value)
  end

  private

  def arel_visitor
    Arel::Visitors::PostgreSQL.new(FakeRecord::Connection.new)
  end
end
