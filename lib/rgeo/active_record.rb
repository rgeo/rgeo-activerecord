# -----------------------------------------------------------------------------
#
# ActiveRecord extensions for RGeo
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
;


# Dependencies
require 'rgeo'
require 'active_record'


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


# The rgeo-activerecord gem installs several patches to Arel to provide
# support for spatial queries.

module Arel
end


# The rgeo-activerecord gem installs several patches to ActiveRecord
# to support services needed by spatial adapters.

module ActiveRecord
end


# Implementation files
require 'rgeo/active_record/version.rb'
require 'rgeo/active_record/spatial_expressions.rb'
require 'rgeo/active_record/arel_spatial_queries'
require 'rgeo/active_record/common_adapter_elements.rb'
require 'rgeo/active_record/ar_factory_settings'
require 'rgeo/active_record/geometry_mixin'
