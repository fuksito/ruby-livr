module LIVR
  class Rule

    def initialize(*)
    end

    def call(value, user_data, field_results)
      raise NotImplementedError
    end

    private

    def is_primitive(value)
      [Numeric, String, TrueClass, FalseClass].any?{|klass| value.is_a?(klass) }
    end

    def is_no_value(value)
      value == nil || value == ""
    end
  end
end