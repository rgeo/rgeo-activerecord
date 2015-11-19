## RGeo::ActiveRecord

[![Gem Version](https://badge.fury.io/rb/rgeo-activerecord.svg)](http://badge.fury.io/rb/rgeo-activerecord)
[![Build Status](https://travis-ci.org/rgeo/rgeo-activerecord.svg?branch=master)](https://travis-ci.org/rgeo/rgeo-activerecord)
[![Code Climate](https://codeclimate.com/github/rgeo/rgeo-activerecord.png)](https://codeclimate.com/github/rgeo/rgeo-activerecord)

RGeo::ActiveRecord is an optional [RGeo](http://github.com/dazuma/rgeo) module
providing spatial extensions for ActiveRecord, as well as a set of helpers for
writing spatial ActiveRecord adapters based on RGeo.

### Summary

RGeo is a key component for writing location-aware applications in the Ruby
programming language. At its core is an implementation of the industry
standard OGC Simple Features Specification, which provides data
representations of geometric objects such as points, lines, and polygons,
along with a set of geometric analysis operations. See the README for the
"rgeo" gem for more information.

RGeo::ActiveRecord is an optional RGeo add-on module providing spatial
extensions for ActiveRecord, as well as a set of helpers for writing spatial
ActiveRecord adapters based on RGeo.

### Installation

Gemfile:

```ruby
gem 'rgeo-activerecord'
```

`rgeo-activerecord` has the following requirements:

* Ruby 1.9.3 or later
* rgeo 0.3.20 or later.

The latest version supports ActiveRecord 4.2 and later.

Version `1.1.0` supports ActiveRecord 4.0 and 4.1

Version `0.6.0` supports earlier versions of ruby and ActiveRecord:

* Ruby 1.8.7 or later
* ActiveRecord 3.0.3 - 3.2.x
* rgeo 0.3.20 or later
* arel 2.0.6 or later

### Spatial Factories for Columns

`rgeo_factory_generator` and related methods were removed in version 4.0, since column types
are no longer tied to their database column in ActiveRecord 4.2.

Register spatial factories in the `SpatialFactoryStore` singleton class. Each spatial type
in your ActiveRecord models will use the `SpatialFactoryStore` to retrieve
a factory matching the properties of its type. For example, you can set a different
spatial factory for point types, or for types matching a specific SRID, or having
a Z coordinate, or any combination of attributes.

The supported keys when registering a spatial type are listed here with their default values
and other allowed values:

```
geo_type: "geometry", # point, polygon, line_string, geometry_collection, 
                      # multi_line_string, multi_point, multi_polygon
has_m:    false,      # true
has_z:    false,      # true
sql_type: "geometry", # geography
srid:     0,          # (any valid SRID)
```

The default factories are `RGeo::Geographic.spherical_factory` for 
geographic types, and `RGeo::Cartesian.preferred_factory` for geometric types.

Here is an example setup:

```ruby
RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
  # By default, use the GEOS implementation for spatial columns.
  config.default = RGeo::Geos.factory_generator

  # But use a geographic implementation for point columns.
  config.register(RGeo::Geographic.spherical_factory(srid: 4326), geo_type: "point")
end
```

### RGeo Dependency

See the README for the [rgeo](https://github.com/rgeo/rgeo) gem, a dependency, for further
installation information.

### Development and support

This README is the official documentation.

RDoc documentation is available at http://rdoc.info/gems/rgeo-activerecord

Source code is hosted on Github at http://github.com/rgeo/rgeo-activerecord

Contributions are welcome. Fork the project on Github.

Report bugs on Github issues at
http://github.com/rgeo/rgeo-activerecord/issues

Support available on the rgeo-users google group at
http://groups.google.com/group/rgeo-users

### Acknowledgments

[Daniel Azuma](http://www.daniel-azuma.com) created RGeo.
[Tee Parham](http://twitter.com/teeparham) is the current maintainer.

Development is supported by:

* [Pirq](http://pirq.com)
* [Neighborland](https://neighborland.com)

### License

Copyright 2015 Daniel Azuma, Tee Parham

https://github.com/rgeo/rgeo-activerecord/blob/master/LICENSE.txt
