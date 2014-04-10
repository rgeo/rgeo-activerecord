# -----------------------------------------------------------------------------
#
# Tests for basic ActiveRecord extensions
#
# -----------------------------------------------------------------------------
# Copyright 2010-2012 Daniel Azuma
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the copyright holder, nor the names of any other
#   contributors to this software, may be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------

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
