# -----------------------------------------------------------------------------
# 
# Mysqlgeo adapter for ActiveRecord
# 
# -----------------------------------------------------------------------------
# Copyright 2010 Daniel Azuma
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


require 'arel'


# The rgeo-activerecord gem installs several minor hacks into Arel to
# support geometry values in the AST.
module Arel
  
  # Hack Attributes dispatcher to recognize geometry columns.
  # This is deprecated but necessary to support legacy Arel versions.
  module Attributes  # :nodoc:
    class << self
      if method_defined?(:for)
        alias_method :for_without_geometry, :for
        def for(column_)
          column_.type == :geometry ? Attribute : for_without_geometry(column_)
        end
      end
    end
  end
  
  # Visitors are modified to handle RGeo::Feature::Instance objects in
  # the AST.
  module Visitors
    
    # RGeo adds visit_RGeo_Feature_Instance to the Dot visitor.
    class Dot
      alias :visit_RGeo_Feature_Instance :visit_String
    end
    
    # RGeo adds visit_RGeo_Feature_Instance to the DepthFirst visitor.
    class DepthFirst
      alias :visit_RGeo_Feature_Instance :terminal
    end
    
    # RGeo adds visit_RGeo_Feature_Instance to the ToSql visitor.
    class ToSql
      alias :visit_RGeo_Feature_Instance :visit_String
    end
    
  end
  
end
