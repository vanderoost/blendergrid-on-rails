module JsonAccessible
  extend ActiveSupport::Concern

  included do
    self::STORE_ACCESSORS.each do |store, attributes|
      store_accessor store, *attributes.keys, prefix: true

      attributes.each do |attr, type|
        define_method("#{store}_#{attr}=") do |value|
          super case type
                when :integer then value.to_i
                when :float then value.to_f
                when :boolean then ActiveModel::Type::Boolean.new.cast(value)
                else value
                end
        end
      end
    end

    def self.permitted_params
      self::STORE_ACCESSORS.flat_map do |store, attributes|
        attributes.keys.map { |attr| "#{store}_#{attr}".to_sym }
      end
    end
  end
end
