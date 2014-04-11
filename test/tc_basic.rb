require 'test_helper'

module RGeo
  module ActiveRecord
    module Tests  # :nodoc:
      class TestBasic < ::MiniTest::Test  # :nodoc:
        class MyTable < ::ActiveRecord::Base
        end

        def test_has_version
          assert ::RGeo::ActiveRecord::VERSION
        end

        def test_default_factory_generator
          MyTable.rgeo_factory_generator = nil
          factory_ = MyTable.rgeo_factory_for_column(:hello).call(:has_z_coordinate => true, :srid => 4326)
          assert_equal(true, factory_.property(:has_z_coordinate))
          assert_equal(true, factory_.property(:is_cartesian))
          assert_nil(factory_.property(:is_geographic))
          assert_equal(4326, factory_.srid)
        end

        def test_set_factory_generator
          MyTable.rgeo_factory_generator = ::RGeo::Geographic.method(:spherical_factory)
          factory_ = MyTable.rgeo_factory_for_column(:hello, :has_z_coordinate => true, :srid => 4326)
          assert_equal(true, factory_.property(:has_z_coordinate))
          assert_equal(true, factory_.property(:is_geographic))
          assert_nil(factory_.property(:is_cartesian))
          assert_equal(false, factory_.has_projection?)
          assert_equal(4326, factory_.srid)
        end

        def test_specific_factory_for_column
          MyTable.rgeo_factory_generator = nil
          MyTable.set_rgeo_factory_for_column(:foo, ::RGeo::Geographic.simple_mercator_factory(:has_z_coordinate => true))
          factory_ = MyTable.rgeo_factory_for_column(:foo)
          assert_equal(true, factory_.property(:has_z_coordinate))
          assert_equal(true, factory_.property(:is_geographic))
          assert_nil(factory_.property(:is_cartesian))
          assert_equal(true, factory_.has_projection?)
          assert_equal(4326, factory_.srid)
        end

        def test_default_as_json_wkt
          GeometryMixin.set_json_generator(nil)
          factory_ = ::RGeo::Cartesian.preferred_factory
          p_ = factory_.point(1, 2)
          assert_equal("POINT (1.0 2.0)", p_.as_json)
        end

        def test_default_as_json_geojson
          GeometryMixin.set_json_generator(:geojson)
          factory_ = ::RGeo::Cartesian.preferred_factory
          p_ = factory_.point(1, 2)
          assert_equal({'type' => 'Point', 'coordinates' => [1.0, 2.0]}, p_.as_json)
        end

        def test_arel_visit_SpatialConstantNode
          visitor = arel_visitor
          sql = visitor.accept(Arel.spatial('POINT (1.0 2.0)'))
          assert_equal("ST_WKTToSQL('POINT (1.0 2.0)')", sql)
        end
      end
    end
  end
end
