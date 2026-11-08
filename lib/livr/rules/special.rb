module LIVR
  module Rules
    module Special

      class Email < Rule
        # The same expression as in the reference implementation: one "@" only and no "_" in the domain.
        # [:space:] is Unicode-aware, like \s in JavaScript. \A and \z, not ^ and $: they match at line breaks.
        EMAIL_RE = /\A(?:[^<>()\[\]\\.,;:[:space:]@"]+(?:\.[^<>()\[\]\\.,;:[:space:]@"]+)*|"[^@\n\r\u2028\u2029]+")@(?:\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\]|(?:[a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,})\z/

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          return "WRONG_EMAIL" unless EMAIL_RE.match(value.to_s)
          return
        end
      end

      class EqualToField < Rule
        def initialize(field, *)
          @field = field
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          # Compared as strings: "10" and 10 are equal. A missing field is not equal to any value.
          other_value = user_data[@field]
          return "FIELDS_NOT_EQUAL" unless is_primitive(other_value) && value.to_s == other_value.to_s
        end
      end

      class Url < Rule
        # Letters of host labels: Latin letters and U+00A1-U+FFFF, so Unicode hosts (пример.рф) pass.
        # Both cases are listed instead of the "i" flag: with it a class matches "ss" or "ff" as one
        # letter (ß, ﬀ), and labels would not be counted in characters
        LETTER = 'a-zA-Z\u00a1-\uffff'

        # 1-63 characters, not starting or ending with "-". "." is not in a label, so labels do not overlap
        LABEL = "[#{LETTER}0-9](?:[#{LETTER}0-9-]{0,61}[#{LETTER}0-9])?"

        # The first byte is 1-223, the last one is not 255
        IPV4 = '(?:[1-9]\d?|1\d\d|2[0-1]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[0-9]\d?|1\d\d|2[0-4]\d|25[0-4]))'

        # 0-65535 in 1-5 digits
        PORT = '(?:[0-9]{1,4}|[0-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])'

        # Optional user info, then an IPv4 address, labels with a top-level domain of 2-63 letters or
        # localhost, no dot after the host. The scheme and localhost are case-insensitive.
        # \A and \z, not ^ and $: they match at line breaks in Ruby.
        URL_RE_STR = "\\A(?i:https?)://(?:\\S+@)?(?:#{IPV4}|(?:#{LABEL}\\.)+[#{LETTER}]{2,63}|(?i:localhost))" \
                     "(?::#{PORT})?(?:[/?#]\\S*)?\\z"
        URL_RE = Regexp.compile(URL_RE_STR)
        MAX_URL_LENGTH = 2083

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          if value.to_s.length < MAX_URL_LENGTH && URL_RE.match(value.to_s)
            return
          else
            'WRONG_URL'
          end
        end
      end

      # LIVR 2.5: what iso_date, iso_datetime and iso_time share
      class DateRule < Rule
        DAY_MS = 86_400_000
        UNIX_EPOCH_DAY = 2_440_588 # the Julian day number of 1970-01-01

        # Bounds relative to the current date in UTC
        RELATIVE_DAYS = { "yesterday" => -1, "today" => 0, "tomorrow" => 1 }.freeze

        DATE_RE = /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/

        # A bound is a fixed value, or days from the current date
        Bound = Struct.new(:value, :is_relative)

        private

        # The options object, nil without arguments. Arguments after it are ignored
        def options_argument(rule_name, args)
          return if args.empty?

          options = args.first
          unless options.is_a?(Hash)
            raise "Rule [#{rule_name}] takes no arguments or an object with \"min\" and \"max\" first, got #{options.inspect}"
          end

          options = options.stringify_keys
          unknown = options.keys - %w[min max]
          raise "Rule [#{rule_name}] got an unknown option #{unknown.first.inspect}" if unknown.any?

          options
        end

        # No value could pass: both bounds are fixed or both are relative. A fixed and a relative
        # bound depend on the day ({"min" => "2026-12-01", "max" => "today"} accepts nothing before December)
        def check_bounds_order(rule_name, min, max)
          return unless min && max && min.is_relative == max.is_relative && min.value > max.value
          raise "Rule [#{rule_name}] got \"min\" later than \"max\""
        end

        def relative_bound(bound)
          Bound.new(RELATIVE_DAYS[bound], true) if RELATIVE_DAYS.has_key?(bound)
        end

        # The day of a date YYYY-MM-DD (the Julian day number), nil when it is not a valid date.
        # The proleptic Gregorian calendar, as ISO 8601: Date uses the Julian calendar before
        # 1582-10-15 by default, so "1582-10-10" would not be a date and "1500-02-29" would be
        def date_day(value)
          match = DATE_RE.match(value)
          return unless match

          year, month, day = match.captures.map(&:to_i)
          Date.civil(year, month, day, Date::GREGORIAN).jd if Date.valid_civil?(year, month, day, Date::GREGORIAN)
        end

        # The current date in UTC, never in the local time zone: the system clock, read for every value
        def today
          Time.now.to_i.div(86_400) + UNIX_EPOCH_DAY
        end
      end

      class IsoDate < DateRule
        # iso_date, as in LIVR 2.0, or iso_date({"min" => ..., "max" => ...}) in LIVR 2.5
        def initialize(*args)
          options = options_argument("iso_date", args)
          return unless options

          @min = date_bound(options, "min")
          @max = date_bound(options, "max")
          check_bounds_order("iso_date", @min, @max)
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          # Numbers and booleans are not dates
          day = date_day(value) if value.is_a?(::String)
          return "WRONG_DATE" unless day

          return "DATE_TOO_EARLY" if @min && day < bound_day(@min)
          return "DATE_TOO_LATE" if @max && day > bound_day(@max)
        end

        private

        # A date YYYY-MM-DD, "today", "yesterday" or "tomorrow"
        def date_bound(options, name)
          return unless options.has_key?(name)

          bound = options[name]
          day = date_day(bound) if bound.is_a?(::String)
          return Bound.new(day, false) if day

          relative_bound(bound) or raise "Rule [iso_date] takes a date YYYY-MM-DD, \"today\", \"yesterday\" or \"tomorrow\" as \"#{name}\", got #{bound.inspect}"
        end

        def bound_day(bound)
          bound.is_relative ? today + bound.value : bound.value
        end
      end

      # LIVR 2.5: a date and a time with an offset, the output is the instant in UTC
      class IsoDatetime < DateRule
        DATETIME_RE = /\A([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2})(?::([0-9]{2})(?:\.([0-9]{1,9}))?)?(?:Z|([+-])([0-9]{2}):([0-9]{2}))\z/

        def initialize(*args)
          options = options_argument("iso_datetime", args)
          return unless options

          @min = datetime_bound(options, "min")
          @max = datetime_bound(options, "max")
          check_bounds_order("iso_datetime", @min, @max)
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          # The format first: a value outside the years 0000-9999 in UTC is wrong, whatever the bounds
          instant = datetime_instant(value) if value.is_a?(::String)
          output = format_utc(instant) if instant
          return "WRONG_DATETIME" unless output

          return "DATETIME_TOO_EARLY" if @min && instant < bound_instant(@min, 0)
          return "DATETIME_TOO_LATE" if @max && instant > bound_instant(@max, DAY_MS - 1)

          field_results << output
          return
        end

        private

        # The instant in milliseconds from the start of the Julian day 0, cut to milliseconds.
        # nil when the value is not a datetime
        def datetime_instant(value)
          match = DATETIME_RE.match(value)
          return unless match

          year, month, day, hours, minutes, seconds = match[1..6].map(&:to_i)
          offset_hours = match[9].to_i
          offset_minutes = match[10].to_i
          return if hours > 23 || minutes > 59 || seconds > 59 || offset_hours > 23 || offset_minutes > 59
          return unless Date.valid_civil?(year, month, day, Date::GREGORIAN)

          offset = (offset_hours * 60 + offset_minutes) * 60_000
          offset = -offset if match[8] == "-"
          milliseconds = match[7].to_s[0, 3].ljust(3, "0").to_i

          Date.civil(year, month, day, Date::GREGORIAN).jd * DAY_MS +
            ((hours * 60 + minutes) * 60 + seconds) * 1000 + milliseconds - offset
        end

        # YYYY-MM-DDTHH:MM:SS.sssZ, nil outside the years 0000-9999
        def format_utc(instant)
          days, milliseconds = instant.divmod(DAY_MS)
          date = Date.jd(days, Date::GREGORIAN)
          return unless date.year.between?(0, 9999)

          seconds, milliseconds = milliseconds.divmod(1000)
          format("%04d-%02d-%02dT%02d:%02d:%02d.%03dZ", date.year, date.month, date.day,
                 seconds / 3600, seconds / 60 % 60, seconds % 60, milliseconds)
        end

        # A datetime, a date YYYY-MM-DD (the start of the UTC day as "min", its end as "max"),
        # "today", "yesterday" or "tomorrow". A datetime bound may be of any year: it is only compared
        def datetime_bound(options, name)
          return unless options.has_key?(name)

          bound = options[name]
          end_of_day = name == "max" ? DAY_MS - 1 : 0

          if bound.is_a?(::String)
            day = date_day(bound)
            return Bound.new(day * DAY_MS + end_of_day, false) if day

            instant = datetime_instant(bound)
            return Bound.new(instant, false) if instant
          end

          relative_bound(bound) or raise "Rule [iso_datetime] takes a datetime with an offset, a date YYYY-MM-DD, \"today\", \"yesterday\" or \"tomorrow\" as \"#{name}\", got #{bound.inspect}"
        end

        def bound_instant(bound, end_of_day)
          bound.is_relative ? (today + bound.value) * DAY_MS + end_of_day : bound.value
        end
      end

      # LIVR 2.5: a time of day HH:MM, HH:MM:SS or HH:MM:SS.fraction, without an offset
      class IsoTime < DateRule
        TIME_RE = /\A([0-9]{2}):([0-9]{2})(?::([0-9]{2})(?:\.([0-9]{1,9}))?)?\z/

        def initialize(*args)
          options = options_argument("iso_time", args)
          return unless options

          @min = time_bound(options, "min")
          @max = time_bound(options, "max")
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          time = nanoseconds(value) if value.is_a?(::String)
          return "WRONG_TIME" unless time

          if @min && @max && @min > @max
            # A range over midnight: a time in the gap gets the error of the nearer bound
            return if time >= @min || time <= @max
            return time - @max < @min - time ? "TIME_TOO_LATE" : "TIME_TOO_EARLY"
          end

          return "TIME_TOO_EARLY" if @min && time < @min
          return "TIME_TOO_LATE" if @max && time > @max
        end

        private

        # Nanoseconds since midnight, nil when the value is not a time
        def nanoseconds(value)
          match = TIME_RE.match(value)
          return unless match

          hours, minutes, seconds = match[1..3].map(&:to_i)
          return if hours > 23 || minutes > 59 || seconds > 59

          ((hours * 60 + minutes) * 60 + seconds) * 1_000_000_000 + match[4].to_s.ljust(9, "0").to_i
        end

        def time_bound(options, name)
          return unless options.has_key?(name)

          bound = options[name]
          time = nanoseconds(bound) if bound.is_a?(::String)
          time or raise "Rule [iso_time] takes a time HH:MM, HH:MM:SS or HH:MM:SS.fraction as \"#{name}\", got #{bound.inspect}"
        end
      end

    end
  end
end
