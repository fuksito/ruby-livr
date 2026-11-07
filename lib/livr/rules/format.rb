module LIVR
  module Rules
    # LIVR 2.5. Format rules check the string form of a value and output it. Every grammar
    # matches the whole string (\A and \z, not ^ and $) with ASCII classes ([0-9], not \d)
    module Format

      # A boolean has no format: true is not a hostname, "true" is. Subclasses define
      # error_code and valid?(string)
      class FormatRule < Rule
        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' unless is_primitive(value)
          return error_code if value == true || value == false

          value = string_form(value)
          return error_code unless valid?(value)

          field_results << value
          return
        end

        private

        # ip and cidr: no arguments (both versions), "v4" or "v6"
        def ip_version(rule_name, args)
          version = string_argument(args.first) unless args.empty?
          raise "Rule [#{rule_name}] takes no arguments, \"v4\" or \"v6\"" unless args.empty? || %w[v4 v6].include?(version)
          version
        end
      end

      IPV4_RE = /\A(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\z/
      HEX_GROUP_RE = /\A[0-9a-fA-F]{1,4}\z/

      # RFC 4291, section 2.2: eight groups of 1-4 hex digits, one "::" for one or more groups
      # of zeros, an IPv4 address as the last two groups
      def self.ipv6?(value)
        parts = value.split("::", -1)
        return false if parts.empty? || parts.size > 2 # "" or more than one "::"

        groups = parts.map { |part| part.empty? ? [] : part.split(":", -1) }
        count = groups.sum(&:size)
        if groups.last.any? && IPV4_RE.match?(groups.last.last)
          groups.last.pop
          count += 1
        end

        return false unless groups.all? { |part| part.all? { |group| HEX_GROUP_RE.match?(group) } }
        parts.size == 1 ? count == 8 : count <= 7
      end


      class Uuid < FormatRule
        UUID_RE = /\A[0-9a-f]{8}-[0-9a-f]{4}-([1-8])[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
        NIL_OR_MAX_RE = /\A(?:00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)\z/i

        # No versions: any version 1-8, the nil and the max UUID too
        def initialize(*versions)
          @versions = versions.map do |version|
            unless string_argument(version).to_s.match?(/\Av[1-8]\z/)
              raise "Rule [uuid] takes versions \"v1\"-\"v8\", got #{version.inspect}"
            end
            version[1]
          end
        end

        def error_code
          'WRONG_UUID'
        end

        def valid?(value)
          match = UUID_RE.match(value)
          return @versions.include?(match[1]) if match && @versions.any?
          !!match || (@versions.empty? && NIL_OR_MAX_RE.match?(value))
        end
      end

      class Ip < FormatRule
        def initialize(*args)
          @version = ip_version("ip", args)
        end

        def error_code
          'WRONG_IP'
        end

        def valid?(value)
          (@version != "v6" && IPV4_RE.match?(value)) || (@version != "v4" && Format.ipv6?(value))
        end
      end

      # An ip address, "/" and a prefix length without leading zeros. Host bits may be set
      class Cidr < FormatRule
        PREFIX_RE = /\A(?:0|[1-9][0-9]{0,2})\z/

        def initialize(*args)
          @version = ip_version("cidr", args)
        end

        def error_code
          'WRONG_CIDR'
        end

        def valid?(value)
          address, prefix = value.split("/", 2)
          return false unless prefix && PREFIX_RE.match?(prefix)

          if @version != "v6" && IPV4_RE.match?(address)
            prefix.to_i <= 32
          elsif @version != "v4" && Format.ipv6?(address)
            prefix.to_i <= 128
          else
            false
          end
        end
      end

      # RFC 1123 labels separated by "."; the last label is not all digits, so a hostname is never an IPv4 address
      class Hostname < FormatRule
        HOSTNAME_RE = /\A[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\z/
        DIGITS_LABEL_RE = /(?:\A|\.)[0-9]+\z/

        def initialize(*args)
          no_arguments("hostname", args)
        end

        def error_code
          'WRONG_HOSTNAME'
        end

        def valid?(value)
          value.length <= 253 && HOSTNAME_RE.match?(value) && !DIGITS_LABEL_RE.match?(value)
        end
      end

      # RFC 4648: the standard alphabet with padding, or with "url" the URL-safe one with optional padding
      class Base64 < FormatRule
        BASE64_RE = %r{\A(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?\z}
        BASE64_URL_RE = /\A(?:[A-Za-z0-9_-]{4})*(?:[A-Za-z0-9_-]{2}(?:==)?|[A-Za-z0-9_-]{3}=?)?\z/

        def initialize(*args)
          unless args.empty? || string_argument(args.first) == "url"
            raise "Rule [base64] takes no arguments or \"url\""
          end
          @re = args.empty? ? BASE64_RE : BASE64_URL_RE
        end

        def error_code
          'WRONG_BASE64'
        end

        def valid?(value)
          @re.match?(value)
        end
      end

      class Hex < FormatRule
        def initialize(*args)
          no_arguments("hex", args)
        end

        def error_code
          'WRONG_HEX'
        end

        def valid?(value)
          value.match?(/\A[0-9a-fA-F]+\z/)
        end
      end

      class Digest < FormatRule
        LENGTHS = { "md5" => 32, "sha1" => 40, "sha256" => 64, "sha384" => 96, "sha512" => 128 }.freeze

        def initialize(*algorithms)
          @lengths = algorithms.map do |algorithm|
            LENGTHS[string_argument(algorithm)] or raise "Rule [digest] takes one or more of #{LENGTHS.keys.join(', ')}, got #{algorithm.inspect}"
          end
          raise "Rule [digest] takes one or more of #{LENGTHS.keys.join(', ')}" if @lengths.empty?
        end

        def error_code
          'WRONG_DIGEST'
        end

        def valid?(value)
          @lengths.include?(value.length) && value.match?(/\A[0-9a-fA-F]+\z/)
        end
      end

      class MongoId < FormatRule
        def initialize(*args)
          no_arguments("mongo_id", args)
        end

        def error_code
          'WRONG_MONGO_ID'
        end

        def valid?(value)
          value.match?(/\A[0-9a-fA-F]{24}\z/)
        end
      end

      class HexColor < FormatRule
        def initialize(*args)
          no_arguments("hex_color", args)
        end

        def error_code
          'WRONG_HEX_COLOR'
        end

        def valid?(value)
          value.match?(/\A#(?:[0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\z/)
        end
      end

      # 48 (the default) or 64 bits: pairs of hex digits separated by ":" or "-", the same everywhere
      class Mac < FormatRule
        MAC_RE = {
          48 => /\A[0-9a-fA-F]{2}([:-])[0-9a-fA-F]{2}(?:\1[0-9a-fA-F]{2}){4}\z/,
          64 => /\A[0-9a-fA-F]{2}([:-])[0-9a-fA-F]{2}(?:\1[0-9a-fA-F]{2}){6}\z/
        }.freeze

        def initialize(*args)
          @re = MAC_RE[args.empty? ? 48 : count_argument(args.first)]
          raise "Rule [mac] takes no arguments, 48 or 64" unless @re
        end

        def error_code
          'WRONG_MAC'
        end

        def valid?(value)
          @re.match?(value)
        end
      end

      class E164 < FormatRule
        def initialize(*args)
          no_arguments("e164", args)
        end

        def error_code
          'WRONG_E164'
        end

        def valid?(value)
          value.match?(/\A\+[1-9][0-9]{6,14}\z/)
        end
      end

      # Semantic Versioning 2.0.0, the suggested regular expression of semver.org with ASCII classes
      class Semver < FormatRule
        SEMVER_RE = /\A(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)(?:-(?:0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*)?(?:\+[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*)?\z/

        def initialize(*args)
          no_arguments("semver", args)
        end

        def error_code
          'WRONG_SEMVER'
        end

        def valid?(value)
          SEMVER_RE.match?(value)
        end
      end

      # The structure of the JWS compact serialization: three base64url segments without padding,
      # the signature may be empty. No segment length is 1 modulo 4. Nothing is decoded
      class Jwt < FormatRule
        JWT_RE = /\A[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*\z/

        def initialize(*args)
          no_arguments("jwt", args)
        end

        def error_code
          'WRONG_JWT'
        end

        def valid?(value)
          JWT_RE.match?(value) && value.split(".", -1).none? { |segment| segment.length % 4 == 1 }
        end
      end

    end
  end
end
