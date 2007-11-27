require "has_many_exclusive_conditions"

ActiveRecord::Base.send :extend, HasManyExclusiveConditions::Base
ActiveRecord::Associations::HasManyAssociation.send :include, HasManyExclusiveConditions::Association