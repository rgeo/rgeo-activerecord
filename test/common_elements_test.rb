# frozen_string_literal: true

require "test_helper"

class CommonElementsTest < Minitest::Test
  class Feature
    def test
      9
    end
  end

  class Point
    def test
      8
    end
  end

  def test_geometric_type_from_name
    assert_equal RGeo::ActiveRecord.geometric_type_from_name(:point), RGeo::Feature::Point
    assert_equal RGeo::ActiveRecord.geometric_type_from_name(:polygon), RGeo::Feature::Polygon
    assert_equal RGeo::ActiveRecord.geometric_type_from_name(:geometry), RGeo::Feature::Geometry
    assert_equal RGeo::ActiveRecord.geometric_type_from_name(:linestring), RGeo::Feature::LineString
    assert_equal RGeo::ActiveRecord.geometric_type_from_name(:geometrycollection), RGeo::Feature::GeometryCollection
    assert_equal RGeo::ActiveRecord.geometric_type_from_name(:multipoint), RGeo::Feature::MultiPoint
    assert_equal RGeo::ActiveRecord.geometric_type_from_name(:multilinestring), RGeo::Feature::MultiLineString
    assert_equal RGeo::ActiveRecord.geometric_type_from_name(:multipolygon), RGeo::Feature::MultiPolygon
  end

  def test_no_namespace_confusion
    assert_equal 9, Feature.new.test
  end
end
