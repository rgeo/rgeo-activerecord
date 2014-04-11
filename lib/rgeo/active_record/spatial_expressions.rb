module RGeo
  module ActiveRecord
    # Returns true if spatial expressions (i.e. the methods in the
    # SpatialExpressions module) are supported. Generally, this is true
    # if Arel is at version 2.1 or later.

    def self.spatial_expressions_supported?
      defined?(::Arel::Nodes::NamedFunction)
    end

    # A set of spatial expression builders.
    # These methods can be chained off other spatial expressions to form
    # complex expressions.
    #
    # These functions require Arel 2.1 or later.
    module SpatialExpressions
      #--
      # Generic functions
      #++

      def st_function(function_, *args_)
        spatial_info_ = args_.last.is_a?(::Array) ? args_.pop : []
        ::RGeo::ActiveRecord::SpatialNamedFunction.new(function_, [self] + args_, spatial_info_)
      end

      #--
      # Geometry functions
      #++

      def st_dimension
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Dimension', [self], [false, true])
      end

      def st_geometrytype
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_GeometryType', [self], [false, true])
      end

      def st_astext
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_AsText', [self], [false, true])
      end

      def st_asbinary
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_AsBinary', [self], [false, true])
      end

      def st_srid
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_SRID', [self], [false, true])
      end

      def st_isempty
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_IsEmpty', [self], [false, true])
      end

      def st_issimple
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_IsSimple', [self], [false, true])
      end

      def st_boundary
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Boundary', [self], [true, true])
      end

      def st_envelope
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Envelope', [self], [true, true])
      end

      def st_equals(rhs_)
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Equals', [self, rhs_], [false, true, true])
      end

      def st_disjoint(rhs_)
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Disjoint', [self, rhs_], [false, true, true])
      end

      def st_intersects(rhs_)
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Intersects', [self, rhs_], [false, true, true])
      end

      def st_touches(rhs_)
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Touches', [self, rhs_], [false, true, true])
      end

      def st_crosses(rhs_)
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Crosses', [self, rhs_], [false, true, true])
      end

      def st_within(rhs_)
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Within', [self, rhs_], [false, true, true])
      end

      def st_contains(rhs_)
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Contains', [self, rhs_], [false, true, true])
      end

      def st_overlaps(rhs_)
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Overlaps', [self, rhs_], [false, true, true])
      end

      def st_relate(rhs_, matrix_=nil)
        args_ = [self, rhs_]
        args_ << matrix.to_s if matrix_
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Relate', args_, [false, true, true, false])
      end

      def st_distance(rhs_, units_=nil)
        args_ = [self, rhs_]
        args_ << units.to_s if units_
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Distance', args_, [false, true, true, false])
      end

      def st_intersection(rhs_)
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Intersection', [self, rhs_], [true, true, true])
      end

      def st_difference(rhs_)
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Difference', [self, rhs_], [true, true, true])
      end

      def st_union(rhs_)
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Union', [self, rhs_], [true, true, true])
      end

      def st_symdifference(rhs_)
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_SymDifference', [self, rhs_], [true, true, true])
      end

      def st_buffer(distance_, units_=nil)
        args_ = [self, distance_.to_f]
        args_ << units.to_s if units_
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Buffer', args_, [true, true, false])
      end

      def st_convexhull
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_ConvexHull', [self], [true, true])
      end


      #--
      # Point functions
      #++

      def st_x
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_X', [self], [false, true])
      end

      def st_y
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Y', [self], [false, true])
      end

      def st_z
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Z', [self], [false, true])
      end

      def st_m
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_M', [self], [false, true])
      end


      #--
      # Curve functions
      #++

      def st_startpoint
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_StartPoint', [self], [true, true])
      end

      def st_endpoint
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_EndPoint', [self], [true, true])
      end

      def st_isclosed
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_IsClosed', [self], [false, true])
      end

      def st_isring
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_IsRing', [self], [false, true])
      end

      def st_length(units_=nil)
        args_ = [self]
        args_ << units.to_s if units_
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Length', args_, [false, true, false])
      end


      #--
      # LineString functions
      #++

      def st_numpoints
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_NumPoints', [self], [false, true])
      end

      def st_pointn(n_)
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_PointN', [self, n_.to_i], [true, true, false])
      end


      #--
      # Surface functions
      #++

      def st_area(units_=nil)
        args_ = [self]
        args_ << units.to_s if units_
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_StartPoint', args_, [false, true, false])
      end

      def st_centroid
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_Centroid', [self], [true, true])
      end

      def st_pointonsurface
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_PointOnSurface', [self], [true, true])
      end

      #--
      # Polygon functions
      #++

      def st_exteriorring
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_ExteriorRing', [self], [true, true])
      end

      def st_numinteriorrings
        # Note: the name difference is intentional. The standard
        # names this function incorrectly.
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_NumInteriorRing', [self], [false, true])
      end

      def st_interiorringn(n_)
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_InteriorRingN', [self, n_.to_i], [true, true, false])
      end

      #--
      # GeometryCollection functions
      #++

      def st_numgeometries
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_NumGeometries', [self], [false, true])
      end

      def st_geometryn(n_)
        ::RGeo::ActiveRecord::SpatialNamedFunction.new('ST_GeometryN', [self, n_.to_i], [true, true, false])
      end

    end

  end
end

# Add tools to build spatial structures in the AST.

# Allow chaining of spatial expressions from attributes
::Arel::Attribute.send :include, ::RGeo::ActiveRecord::SpatialExpressions


module Arel

  # Create a spatial constant node.
  # This node wraps a spatial value (such as an RGeo feature or a text
  # string in WKT format). It supports chaining with the functions
  # defined by RGeo::ActiveRecord::SpatialExpressions.
  #
  # Requires Arel 2.1 or later.

  def self.spatial(arg_)
    ::RGeo::ActiveRecord::SpatialConstantNode.new(arg_)
  end

end
