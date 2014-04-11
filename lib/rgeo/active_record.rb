# RGeo is a spatial data library for Ruby, provided by the "rgeo" gem.
#
# The optional RGeo::ActiveRecord module provides spatial extensions for
# ActiveRecord, and a set of tools and helpers for writing RGeo-based
# spatial connection adapters.

module RGeo
  # This module contains a set of ActiveRecord extensions for RGeo.
  # Generally, you will not need to interact with the contents of this
  # module directly, unless you are writing a spatial ActiveRecord
  # connection adapter.

  module ActiveRecord
  end
end

require 'rgeo'
require 'active_record'
require 'rgeo/active_record/version'
require 'rgeo/active_record/spatial_expressions'
require 'rgeo/active_record/arel_spatial_queries'
require 'rgeo/active_record/common_adapter_elements'
require 'rgeo/active_record/ar_factory_settings'
require 'rgeo/active_record/geometry_mixin'
