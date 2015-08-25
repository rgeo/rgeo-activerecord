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

### Factory Generator Changes

`rgeo_factory_generator` and related methods were removed in version 4.0.

You can register spatial factories (i.e. a particular combination of settings) for data associated 
with each type in the database.

Here are some examples, given the spatial table defined above:

```ruby
RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
  # By default, use the GEOS implementation for spatial columns.
  config.default = RGeo::Geos.factory_generator

  # But use a geographic implementation for point columns.
  config.register(RGeo::Geographic.spherical_factory(srid: 4326), geo_type: "point")
end
```

See the README for the "rgeo" gem, a required dependency, for further
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
