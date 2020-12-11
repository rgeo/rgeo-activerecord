# frozen_string_literal: true

require "test_helper"

class SpatialFactoryStoreTest < Minitest::Test
  def test_default
    store.default = nil
    assert RGeo::Cartesian.preferred_factory === store.default
  end

  def test_set_default
    store.clear
    default_factory = Object.new
    store.default = default_factory
    assert_equal default_factory, store.default
  end

  def test_register
    store.clear
    default_factory = Object.new
    store.default = default_factory

    point_factory = Object.new
    store.register point_factory, geo_type: "point", srid: 4326
    assert_equal point_factory, store.factory(geo_type: "point", srid: 4326)
    assert_equal 1, store.registry.size
    assert_equal point_factory, store.factory(geo_type: "point", srid: 4326)
    assert_equal 1, store.registry.size

    polygon_factory = Object.new
    store.register polygon_factory, geo_type: "polygon"
    assert_equal polygon_factory, store.factory(geo_type: "polygon")
    assert_equal 2, store.registry.size

    z_point_factory = Object.new
    store.register z_point_factory, geo_type: "point", has_z: true
    assert_equal z_point_factory, store.factory(geo_type: "point", has_z: true)

    assert_equal default_factory, store.factory(geo_type: "linestring")
  end

  def test_register_filter_attrs
    store.clear
    factory = Object.new
    store.register(factory, { geo_type: "point", my_custom_field: "data" })

    assert_equal(store.registry.first.attrs, { geo_type: "point" })
  end

  def test_fetch_factory
    store.clear
    default_factory = Object.new
    store.default = default_factory

    # test fallback
    geom_factory = Object.new
    store.register(geom_factory, { sql_type: "geometry" })
    assert_equal(geom_factory, store.factory({ sql_type: "geometry", srid: 3857 }))

    # test exact match
    geom_merc_factory = Object.new
    store.register(geom_merc_factory, { sql_type: "geometry", srid: 3857 })
    assert_equal(geom_merc_factory, store.factory({ sql_type: "geometry", srid: 3857 }))

    # test mismatched params
    assert_equal(default_factory, store.factory({ sql_type: "geography", srid: 3857 }))
  end

  def test_fetch_factory_specificity
    store.clear
    default_factory = Object.new
    store.default = default_factory

    geom_factory = Object.new
    store.register(geom_factory, { sql_type: "geometry", srid: 3857, geo_type: "point" })
    assert_equal(default_factory, store.factory({ sql_type: "geometry", srid: 3857 }))
  end

  def test_fetch_factory_order
    store.clear
    default_factory = Object.new
    store.default = default_factory

    fac1 = Object.new
    store.register(fac1, { sql_type: "geometry" })

    fac2 = Object.new
    store.register(fac2, { sql_type: "geometry" })

    assert_equal(fac1, store.factory({ sql_type: "geometry" }))
  end

  private

  def store
    RGeo::ActiveRecord::SpatialFactoryStore.instance
  end
end
