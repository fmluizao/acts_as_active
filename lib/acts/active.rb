module Acts #:nodoc:
  module Active

    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
    end

    module ClassMethods
      def acts_as_active(options = {})
        # don't let AR call this twice
        unless self.included_modules.include?(InstanceMethods) 
          cattr_accessor :active_attribute
          self.active_attribute = (options[:with] || :active).to_sym
          
          #show only active
          default_scope :conditions => {self.active_attribute => true}

          #copy the :destroy_without_callbacks
          alias_method :destroy_without_callbacks!, :destroy_without_callbacks
          include InstanceMethods
        end
      end
      
      def find_with_inactive(*args)
        with_exclusive_scope { find(*args) }
      end
      
      def all_with_inactive(*args)
        with_exclusive_scope { all(*args) }
      end
      
      def calculate_with_inactive(*args)
        with_exclusive_scope { calculate(*args) }
      end
      
      def count_with_inactive(*args)
        with_exclusive_scope { count(*args) }
      end
      
    end

    module InstanceMethods
      def active?
        self[active_attribute]
      end
      
      def activate!
        update_attribute active_attribute, true
      end
      
      def deactivate!
        update_attribute active_attribute, false
      end

      #override the default behavior
      def destroy_without_callbacks
        unless new_record?
          deactivate!
        end
        freeze
      end

      def destroy_with_callbacks!
        return false if callback(:before_destroy) == false
        result = destroy_without_callbacks!
        callback(:after_destroy)
        result
      end

      def destroy!
        transaction { destroy_with_callbacks! } #call the original destroy_with_callbacks
      end
      
      private
      def active_attribute
        self.class.active_attribute
      end

    end
  end
end

