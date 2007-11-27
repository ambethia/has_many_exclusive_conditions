# HasManyExclusiveConditions
module HasManyExclusiveConditions
  module Base
    def self.extended(base)
      class << base
        alias_method_chain :create_has_many_reflection, :exclusive_conditions
      end
    end
    
    def create_has_many_reflection_with_exclusive_conditions(association_id, options, &extension)
      options.assert_valid_keys(
        :class_name, :table_name, :foreign_key,
        :dependent,
        :select, :conditions, :exclusive_conditions, :include, :order, :group, :limit, :offset,
        :as, :through, :source, :source_type,
        :uniq,
        :finder_sql, :counter_sql, 
        :before_add, :after_add, :before_remove, :after_remove, 
        :extend
      )

      options[:extend] = create_extension_modules(association_id, extension, options[:extend]) if block_given?

      create_reflection(:has_many, association_id, options, self)
    end
  end

  module Association  
    module InstanceMethods
      def construct_sql_with_exclusive_conditions
        case
          when @reflection.options[:finder_sql]
            @finder_sql = interpolate_sql(@reflection.options[:finder_sql])

          when @reflection.options[:as]
            @finder_sql = 
              "#{@reflection.klass.table_name}.#{@reflection.options[:as]}_id = #{@owner.quoted_id} AND " + 
              "#{@reflection.klass.table_name}.#{@reflection.options[:as]}_type = #{@owner.class.quote_value(@owner.class.base_class.name.to_s)}"
            @finder_sql << " AND (#{conditions})" if conditions
          when @reflection.options[:exclusive_conditions]
            @finder_sql = interpolate_sql(@reflection.options[:exclusive_conditions])
          else
            @finder_sql = "#{@reflection.klass.table_name}.#{@reflection.primary_key_name} = #{@owner.quoted_id}"
            @finder_sql << " AND (#{conditions})" if conditions
        end

        if @reflection.options[:counter_sql]
          @counter_sql = interpolate_sql(@reflection.options[:counter_sql])
        elsif @reflection.options[:finder_sql]
          # replace the SELECT clause with COUNT(*), preserving any hints within /* ... */
          @reflection.options[:counter_sql] = @reflection.options[:finder_sql].sub(/SELECT (\/\*.*?\*\/ )?(.*)\bFROM\b/im) { "SELECT #{$1}COUNT(*) FROM" }
          @counter_sql = interpolate_sql(@reflection.options[:counter_sql])
        else
          @counter_sql = @finder_sql
        end
      end
    
    end
  
    def self.included(base)
      base.send :include, InstanceMethods      
      base.alias_method_chain :construct_sql, :exclusive_conditions
    end
  end

end