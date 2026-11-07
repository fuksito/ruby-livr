module LIVR
  # LIVR 2.5: a reference to another field, in required_if and when. "name" is a field of the
  # containing object, "a/b/0" a path down from it, with "~1" for "/" and "~0" for "~" inside
  # a segment, as in JSON Pointer (RFC 6901)
  module Reference
    # A list index: "0" or a number without leading zeros
    INDEX_RE = /\A(?:0|[1-9][0-9]*)\z/

    # The segments of a reference. Not a string, an empty reference, a leading or a trailing "/",
    # an empty segment ("a//b") and a wrong escape ("~2", a trailing "~") are schema errors
    def self.parse(reference, rule_name)
      reference = reference.to_s if reference.is_a?(Symbol) # Ruby rules may have symbol keys
      unless reference.is_a?(::String) && !reference.empty?
        raise "Rule [#{rule_name}] takes a reference as a non-empty string, got #{reference.inspect}"
      end

      reference.split("/", -1).map do |segment|
        raise "Rule [#{rule_name}] got an empty segment in the reference #{reference.inspect}" if segment.empty?
        raise "Rule [#{rule_name}] got a wrong escape in the reference #{reference.inspect}" if segment.match?(/~(?![01])/)

        segment.gsub("~1", "/").gsub("~0", "~")
      end
    end

    # The input value at the path: nil when a segment is missing or a value on the way is not
    # an object (or a list for an index segment)
    def self.resolve(data, path)
      path.reduce(data) do |value, segment|
        case value
        when Hash
          value.fetch(segment) { value[segment.to_sym] } # Ruby data may have symbol keys
        when Array
          return unless INDEX_RE.match?(segment)
          value[segment.to_i]
        else
          return
        end
      end
    end
  end
end
