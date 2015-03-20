require 'test_helper'

class BasicTest < Minitest::Test # :nodoc:
  class MyTable < ::ActiveRecord::Base
  end

  def test_has_version
    assert RGeo::ActiveRecord::VERSION
  end

  def test_default_factory_generator
    MyTable.rgeo_factory_generator = nil
    factory = MyTable.rgeo_factory_for_column(:hello, has_z_coordinate: true, srid: 4326)
    assert_equal true, factory.property(:has_z_coordinate)
    assert_equal true, factory.property(:is_cartesian)
    assert_nil factory.property(:is_geographic)
    assert_equal 4326, factory.srid
  end

  def test_set_factory_generator
    MyTable.rgeo_factory_generator = RGeo::Geographic.method(:spherical_factory)
    factory = MyTable.rgeo_factory_for_column(:hello, has_z_coordinate: true, srid: 4326)
    assert_equal true, factory.property(:has_z_coordinate)
    assert_equal true, factory.property(:is_geographic)
    assert_nil factory.property(:is_cartesian)
    assert_equal false, factory.has_projection?
    assert_equal 4326, factory.srid
  end

  def test_specific_factory_for_column
    MyTable.rgeo_factory_generator = nil
    MyTable.set_rgeo_factory_for_column(:foo, RGeo::Geographic.simple_mercator_factory(has_z_coordinate: true))
    factory = MyTable.rgeo_factory_for_column(:foo)
    assert_equal true, factory.property(:has_z_coordinate)
    assert_equal true, factory.property(:is_geographic)
    assert_nil factory.property(:is_cartesian)
    assert_equal true, factory.has_projection?
    assert_equal 4326, factory.srid
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
    assert_equal({'type' => 'Point', 'coordinates' => [1.0, 2.0]}, point.as_json)
  end

  def test_arel_visit_spatial_constant_node
    visitor = arel_visitor
    sql = visitor.accept(Arel.spatial('POINT (1.0 2.0)'), Arel::Collectors::PlainString.new)
    assert_equal("ST_WKTToSQL('POINT (1.0 2.0)')", sql.value)
  end

  private

  def arel_visitor
    Arel::Visitors::PostgreSQL.new(Arel::Table.engine.connection)
  end

end
