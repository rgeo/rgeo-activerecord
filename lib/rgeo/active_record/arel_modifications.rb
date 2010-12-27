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


# The rgeo-activerecord gem installs several hacks into Arel to support
# geometry values and geometry-valued columns.
# 
# To support geometry values as nodes in the Arel AST, we need to provide
# a way for visitors to handle nodes that are feature objects.
# Generally, this is accomplished by writing (or aliasing) methods in the
# visitor of the form "visit_<classname>". Arel will dispatch to a method
# based on the class of the object in the AST. Unfortunately, RGeo feature
# objects usually have opaque classes; plus, there are so many different
# classes as to make it infeasible to list all of them. Therefore, we hack
# Arel::Visitors::Visitor#visit to explicitly recognize the
# RGeo::Feature::Instance marker module, and we define the method
# visit_RGeo_Feature_Instance. In the various visitors (Dot, DepthFirst,
# and ToSql), this method is aliased in the same way as the other raw
# values. For the ToSql visitor, this means aliasing to visit_String,
# which then depends on the quoting implemented by the connection adapter
# to convert to a SQL literal.
# 
# To support geometry columns, we define Arel::Attributes::Geometry, and
# we hack Arel::Attributes::for to map the :geometry column type to that
# new attribute. We then add the appropriate alias for the
# visit_Arel_Attributes_Geometry method to the visitors.

module Arel
  
  # :stopdoc:
  
  module Attributes
    
    # New attribute type for geometry-valued column
    class Geometry < Attribute; end
    
    # Hack Attributes dispatcher to recognize geometry columns
    class << self
      alias_method :for_without_geometry, :for
      def for(column_)
        column_.type == :geometry ? Geometry : for_without_geometry(column_)
      end
    end
    
  end
  
  module Visitors
    
    # Hack visit dispatcher to recognize RGeo features as nodes.
    # We need a special dispatcher code because the default dispatcher
    # triggers on class name. RGeo features tend to have opaque classes.
    class Visitor
      alias_method :visit_without_rgeo_types, :visit
      def visit(object_)
        if object_.kind_of?(::RGeo::Feature::Instance) && respond_to?(:visit_RGeo_Feature_Instance)
          visit_RGeo_Feature_Instance(object_)
        else
          visit_without_rgeo_types(object_)
        end
      end
    end
    
    # Dot visitor handlers for geometry attributes and values.
    class Dot
      alias :visit_Arel_Attributes_Geometry :visit_Arel_Attribute
      alias :visit_RGeo_Feature_Instance :visit_String
    end
    
    # DepthFirst visitor handlers for geometry attributes and values.
    class DepthFirst
      alias :visit_Arel_Attributes_Geometry :visit_Arel_Attribute
      alias :visit_RGeo_Feature_Instance :terminal
    end
    
    # ToSql visitor handlers for geometry attributes and values.
    class ToSql
      alias :visit_Arel_Attributes_Geometry :visit_Arel_Attributes_Attribute
      alias :visit_RGeo_Feature_Instance :visit_String
    end
    
  end
  
  # :startdoc:
  
end
