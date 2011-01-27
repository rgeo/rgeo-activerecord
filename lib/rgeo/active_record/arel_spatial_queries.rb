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


module RGeo
  
  module ActiveRecord
    
    
    # A set of common Arel visitor hacks for spatial ToSql visitors.
    # Generally, a spatial ActiveRecord adapter should provide a custom
    # ToSql Arel visitor that includes and customizes this module.
    # See the existing spatial adapters (i.e. postgis, spatialite,
    # mysqlspatial, and mysql2spatial) for usage examples.
    
    module SpatialToSql
      
      
      # Map a standard OGC SQL function name to the actual name used by
      # a particular database. This method should take a name and
      # return either the changed name or the original name.
      
      def st_func(standard_name_)
        standard_name_
      end
      
      
      # Visit the SpatialNamedFunction node. This operates similarly to
      # the standard NamedFunction node, but it performs function name
      # mapping for the database, and it also uses the type information
      # in the node to determine when to cast string arguments to WKT,
      
      def visit_RGeo_ActiveRecord_SpatialNamedFunction(node_)
        name_ = st_func(node_.name)
        exprs_ = []
        node_.expressions.each_with_index do |expr_, index_|
          exprs_ << (node_.spatial_argument?(index_) ? visit_in_spatial_context(expr_) : visit(expr_))
        end
        "#{name_}(#{node_.distinct ? 'DISTINCT ' : ''}#{exprs_.join(', ')})#{node_.alias ? " AS #{visit node_.alias}" : ''}"
      end
      
      
      # Returns a true value if the given node is of spatial type-- that
      # is, if it is a spatial literal or a reference to a spatial
      # attribute.
      
      def node_has_spatial_type?(node_)
        case node_
        when ::Arel::Attribute
          @connection.instance_variable_set(:@_getting_columns, true)
          begin
            col_ = @engine.columns_hash[node_.name.to_s] unless @engine == ::ActiveRecord::Base
            col_ && col_.respond_to?(:spatial?) && col_.spatial? ? true : false
          ensure
            @connection.instance_variable_set(:@_getting_columns, false)
          end
        when ::RGeo::ActiveRecord::SpatialNamedFunction
          node_.spatial_result?
        when ::RGeo::ActiveRecord::SpatialConstantNode, ::RGeo::Feature::Instance
          true
        else
          false
        end
      end
      
      
      # Generates SQL for a spatial node.
      # The node must be a string (in which case it is treated as WKT),
      # an RGeo feature, or a spatial attribute.
      
      def visit_in_spatial_context(node_)
        case node_
        when ::String
          "#{st_func('ST_WKTToSQL')}(#{visit_String(node_)})"
        when ::RGeo::Feature::Instance
          visit_RGeo_Feature_Instance(node_)
        else
          visit(node_)
        end
      end
      
      
      def _check_equality_for_rgeo(node_, negate_)  # :nodoc:
        left_ = node_.left
        right_ = node_.right
        if !@connection.instance_variable_get(:@_getting_columns) && !right_.nil? && (node_has_spatial_type?(left_) || node_has_spatial_type?(right_))
          "#{negate_ ? 'NOT ' : ''}#{st_func('ST_Equals')}(#{visit_in_spatial_context(left_)}, #{visit_in_spatial_context(right_)})"
        else
          false
        end
      end
      
      
      # Override equality nodes to use the ST_Equals function if at least
      # one of the operands is a spatial node.
      
      def visit_Arel_Nodes_Equality(node_)
        _check_equality_for_rgeo(node_, false) || super
      end
      
      
      # Override equality nodes to use the ST_Equals function if at least
      # one of the operands is a spatial node.
      
      def visit_Arel_Nodes_NotEqual(node_)
        _check_equality_for_rgeo(node_, true) || super
      end
      
    end
    
    
  end
  
end


# :stopdoc:


# This node wraps an RGeo feature and gives it spatial expression
# constructors.

module RGeo
  module ActiveRecord
    
    class SpatialConstantNode
      
      include ::RGeo::ActiveRecord::SpatialExpressions
      
      def initialize(delegate_)
        @delegate = delegate_
      end
      
      attr_reader :delegate
      
    end
    
  end
end


# Make sure the standard Arel visitors can handle RGeo feature objects
# by default.

module Arel
  module Visitors
    class Visitor
      def visit_RGeo_ActiveRecord_SpatialConstantNode(node_)
        if respond_to?(:visit_in_spatial_context)
          visit_in_spatial_context(node_.delegate)
        else
          visit(node_.delegate)
        end
      end
    end
    class Dot
      alias :visit_RGeo_Feature_Instance :visit_String
    end
    class DepthFirst
      alias :visit_RGeo_Feature_Instance :terminal
    end
    class ToSql
      alias :visit_RGeo_Feature_Instance :visit_String
    end
  end
end


# Add tools to build spatial structures in the AST.
# This stuff requires Arel 2.1 or later.

if defined?(::Arel::Nodes::NamedFunction)
  
  # Allow chaining of predications from named functions
  # (Hack because Arel doesn't do this but should.)
  ::Arel::Nodes::NamedFunction.class_eval do
    include ::Arel::Predications unless include?(::Arel::Predications)
  end
  
  # Allow chaining of spatial expressions from attributes
  ::Arel::Attribute.class_eval do
    include ::RGeo::ActiveRecord::SpatialExpressions
  end
  
  
  # A NamedFunction subclass that keeps track of the spatial-ness of
  # the arguments and return values, so that it can provide context to
  # visitors that want to interpret syntax differently when dealing with
  # spatial elements.
  
  class ::RGeo::ActiveRecord::SpatialNamedFunction < ::Arel::Nodes::NamedFunction
    
    include ::RGeo::ActiveRecord::SpatialExpressions
    
    def initialize(name_, expr_, spatial_flags_=[], aliaz_=nil)
      super(name_, expr_, aliaz_)
      @spatial_flags = spatial_flags_
    end
    
    def spatial_result?
      @spatial_flags.first
    end
    
    def spatial_argument?(index_)
      @spatial_flags[index_+1]
    end
    
  end
  
else
  
  # A dummy SpatialNamedFunction for pre-2.1 versions of Arel.
  class ::RGeo::ActiveRecord::SpatialNamedFunction; end
  
end


# :startdoc:
