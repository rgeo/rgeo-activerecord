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

      def visit_RGeo_ActiveRecord_SpatialNamedFunction(node_, *args)
        name_ = st_func(node_.name)
        exprs_ = []
        node_.expressions.each_with_index do |expr_, index_|
          exprs_ << (node_.spatial_argument?(index_) ? visit_in_spatial_context(expr_, *args) : visit(expr_, *args))
        end
        "#{name_}(#{node_.distinct ? 'DISTINCT ' : ''}#{exprs_.join(', ')})#{node_.alias ? " AS #{visit(node_.alias, *args)}" : ''}"
      end

      # Generates SQL for a spatial node.
      # The node must be a string (in which case it is treated as WKT),
      # an RGeo feature, or a spatial attribute.
      def visit_in_spatial_context(node_, *args)
        case node_
        when ::String
          "#{st_func('ST_WKTToSQL')}(#{visit_String(node_, *args)})"
        when ::RGeo::Feature::Instance
          visit_RGeo_Feature_Instance(node_, *args)
        when ::RGeo::Cartesian::BoundingBox
          visit_RGeo_Cartesian_BoundingBox(node_, *args)
        else
          visit(node_, *args)
        end
      end
    end

    # This node wraps an RGeo feature and gives it spatial expression
    # constructors.
    class SpatialConstantNode
      include ::RGeo::ActiveRecord::SpatialExpressions

      # The delegate should be the RGeo feature.
      def initialize(delegate_)
        @delegate = delegate_
      end

      # Return the RGeo feature
      attr_reader :delegate
    end

    # :stopdoc:

    # Make sure the standard Arel visitors can handle RGeo feature objects
    # by default.

    ::Arel::Visitors::Visitor.class_eval do
      def visit_RGeo_ActiveRecord_SpatialConstantNode(node_, *args)
        if respond_to?(:visit_in_spatial_context)
          visit_in_spatial_context(node_.delegate, *args)
        else
          visit(node_.delegate, *args)
        end
      end
    end
    ::Arel::Visitors::Dot.class_eval do
      alias :visit_RGeo_Feature_Instance :visit_String
      alias :visit_RGeo_Cartesian_BoundingBox :visit_String
    end
    ::Arel::Visitors::DepthFirst.class_eval do
      alias :visit_RGeo_Feature_Instance :terminal
      alias :visit_RGeo_Cartesian_BoundingBox :terminal
    end
    ::Arel::Visitors::ToSql.class_eval do
      alias :visit_RGeo_Feature_Instance :visit_String
      alias :visit_RGeo_Cartesian_BoundingBox :visit_String
    end


    # A NamedFunction subclass that keeps track of the spatial-ness of
    # the arguments and return values, so that it can provide context to
    # visitors that want to interpret syntax differently when dealing with
    # spatial elements.
    class SpatialNamedFunction < ::Arel::Nodes::NamedFunction
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

    # :startdoc:

  end
end
