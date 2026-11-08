require 'spec_helper.rb'
require 'active_support/testing/time_helpers'

RSpec.describe "LIVR 2.5" do
  include ActiveSupport::Testing::TimeHelpers

  it "numbers have the string form of the specification" do
    validator = LIVR::Validator.new("value" => { "list_of" => { "split" => "|" } })

    output = validator.validate("value" => [1.0, -0.0, 100, 1e3, 0.1, -12.25, 123456789012345, 0.00001, 0.000015])

    expect(output["value"]).to eq([["1"], ["0"], ["100"], ["1000"], ["0.1"], ["-12.25"], ["123456789012345"], ["0.00001"], ["0.000015"]])
  end

  it "split: a separator is a string, not whitespace" do
    validator = LIVR::Validator.new("value" => { "split" => " " })

    expect(validator.validate("value" => "a  b ")).to eq("value" => ["a", "", "b", ""])
  end

  it "today is the current date in UTC, not in the local time zone" do
    validator = LIVR::Validator.new("date" => { "iso_date" => { "max" => "today" } })
    time_zone = ENV["TZ"]
    ENV["TZ"] = "Pacific/Kiritimati" # UTC+14: already 2026-10-30 there

    travel_to(Time.utc(2026, 10, 29, 23, 30)) do
      expect(validator.validate("date" => "2026-10-29")).to eq("date" => "2026-10-29")
      expect(validator.validate("date" => "2026-10-30")).to eq(false)
      expect(validator.get_errors).to eq("date" => "DATE_TOO_LATE")
    end
  ensure
    ENV["TZ"] = time_zone
  end

  it "the clock is read for every validation" do
    validator = LIVR::Validator.new("starts_at" => { "iso_datetime" => { "min" => "tomorrow" } })

    travel_to(Time.utc(2026, 10, 29, 12)) do
      expect(validator.validate("starts_at" => "2026-10-30T00:00Z")).to eq("starts_at" => "2026-10-30T00:00:00.000Z")
    end

    travel_to(Time.utc(2026, 10, 30, 12)) do
      expect(validator.validate("starts_at" => "2026-10-30T00:00Z")).to eq(false)
      expect(validator.get_errors).to eq("starts_at" => "DATETIME_TOO_EARLY")
    end
  end

  it "rules in aliases and or see the fields next to the field, items of list_of see none" do
    validator = LIVR::Validator.new(
      "password"  => "required",
      "password2" => "same_password",
      "password3" => { "or" => [{ "equal_to_field" => "password" }, { "eq" => "" }] },
      "list"      => { "list_of" => { "equal_to_field" => "field" } }
    )
    validator.register_aliased_rule("name" => "same_password", "rules" => { "equal_to_field" => "password" })

    expect(validator.validate("password" => "secret", "password2" => "secret", "password3" => "secret")).to be_truthy

    expect(validator.validate("password" => "secret", "password2" => "other", "list" => ["a"])).to eq(false)
    expect(validator.get_errors).to eq("password2" => "FIELDS_NOT_EQUAL", "list" => ["FIELDS_NOT_EQUAL"])
  end

  it "references and cases work with symbol keys" do
    validator = LIVR::Validator.new(
      type: "required",
      vat:  { required_if: { type: "company" } },
      data: { when: ["type", { company: "required", person: { eq: "" } }] }
    )

    expect(validator.validate(type: "company", data: "x")).to eq(false)
    expect(validator.get_errors).to eq(vat: "REQUIRED")
    expect(validator.validate(type: "person")).to eq(type: "person")
  end

  it "a registered rule replaces the standard rule with the same name" do
    validator = LIVR::Validator.new("subscribe" => "boolean")
    validator.register_rules("boolean" => Class.new(LIVR::Rule) do
      def call(value, user_data, field_results)
        field_results << (value == "on")
        nil
      end
    end)

    expect(validator.validate("subscribe" => "on")).to eq("subscribe" => true)
  end

  it "LIVR 2.0 rules ignore extra arguments and keep custom rules and flags" do
    weak_password = Class.new(LIVR::Rule) do
      def call(value, user_data, field_results)
        "WEAK_PASSWORD" if value.to_s.length < 6
      end
    end

    validator = LIVR::Validator.new(
      "user"  => { "nested_object" => [{ "password" => "weak_password" }, "extra"] },
      "users" => { "list_of_objects" => [{ "password" => "weak_password" }, "extra"] },
      "code"  => { "like" => ["^[a-z]+$", "i", "extra"] },
      "name"  => { "max_length" => [3, "extra"] }
    )
    validator.register_rules("weak_password" => weak_password)

    expect(validator.validate("user" => { "password" => "abc" }, "users" => [{ "password" => "abc" }], "code" => "ABC", "name" => "abcd")).to eq(false)
    expect(validator.get_errors).to eq(
      "user"  => { "password" => "WEAK_PASSWORD" },
      "users" => [{ "password" => "WEAK_PASSWORD" }],
      "name"  => "TOO_LONG"
    )
  end

  it "numbers in arguments of the new rules: a string in the decimal grammar is a number" do
    expect { LIVR::Validator.new("a" => { "max_decimals" => "02" }, "b" => { "mac" => "64.0" }, "c" => { "list_length" => ["1", 2.0] }).prepare }.not_to raise_error

    [" 2", "1e1", "0x40"].each do |argument|
      expect { LIVR::Validator.new("a" => { "max_decimals" => argument }).prepare }.to raise_error(RuntimeError)
    end
  end

  it "null and [] in place of rules are schema errors, also inside a list of rules" do
    [
      { "when" => ["type", { "a" => nil }] },
      { "when" => ["type", "required", "string", nil] },
      { "when" => ["type", "required", ["required", []]] },
      { "values" => ["required", []] },
      { "keys" => [["string", []]] }
    ].each do |rule|
      expect { LIVR::Validator.new("field" => rule).prepare }.to raise_error(RuntimeError, /as rules/)
    end
  end

  it "ignored extra arguments are not checked" do
    validator = LIVR::Validator.new("ids" => { "split" => [",", {}] }, "ip" => { "ip" => ["v4", nil] })

    expect(validator.validate("ids" => "1,2", "ip" => "192.0.2.1")).to eq("ids" => ["1", "2"], "ip" => "192.0.2.1")
  end

  it "schema errors are raised when the validator is built" do
    validator = LIVR::Validator.new("vat" => { "required_if" => { "type" => "" } })

    expect { validator.prepare }.to raise_error(RuntimeError, /required_if/)
  end

  it "null as the argument is one null argument, a schema error for every new rule" do
    LIVR::LIVR_2_5_RULES.each_key do |name|
      expect { LIVR::Validator.new("field" => { name => nil }).prepare }.to raise_error(RuntimeError, /\[#{name}\]/)
    end
  end

  it "null as the argument of iso_date is no arguments, as in LIVR 2.0" do
    validator = LIVR::Validator.new("date" => { "iso_date" => nil })

    expect(validator.validate("date" => "2026-01-01")).to eq("date" => "2026-01-01")
    expect(validator.validate("date" => "2026-02-30")).to eq(false)
    expect(validator.get_errors).to eq("date" => "WRONG_DATE")
  end

  it "null as the argument is no arguments for the LIVR 2.0 and custom rules, as in 2.0" do
    arguments = nil
    my_rule = Class.new(LIVR::Rule) do
      define_method(:initialize) { |*args| arguments = args }
      def call(value, user_data, field_results); end
    end

    validator = LIVR::Validator.new("code" => { "my_rule" => nil })
    validator.register_rules("my_rule" => my_rule)

    expect(validator.validate({})).to eq({})
    expect(arguments).to eq([])

    # Also a custom rule that replaces a new standard rule
    arguments = nil
    validator = LIVR::Validator.new("flag" => { "boolean" => nil })
    validator.register_rules("boolean" => my_rule)

    expect(validator.validate({})).to eq({})
    expect(arguments).to eq([])

    # default takes a value: without one it raises when the validator is built, as in 2.0
    expect { LIVR::Validator.new("name" => { "default" => nil }).prepare }.to raise_error(ArgumentError)
  end

  it "null inside the arguments of the new rules is a wrong value" do
    [
      { "not_one_of" => [nil] },
      { "required_if" => { "type" => nil } },
      { "split" => nil },
      { "list_length" => { "min" => nil } },
      { "list_length" => { "max" => nil } }
    ].each do |rule|
      expect { LIVR::Validator.new("field" => rule).prepare }.to raise_error(RuntimeError)
    end
  end

  it "eq and one_of match a boolean and its string form both ways, as in 2.0" do
    validator = LIVR::Validator.new(
      "a" => { "eq" => "true" },
      "b" => { "eq" => true },
      "c" => { "one_of" => [true, false] },
      "d" => { "one_of" => ["true", "false"] }
    )

    expect(validator.validate("a" => true, "b" => "true", "c" => "false", "d" => false)).to eq(
      "a" => "true", "b" => true, "c" => false, "d" => "false"
    )

    # 2.0 matched only true.to_s: "1" and "True" are other values
    expect(validator.validate("a" => "True", "b" => "1", "c" => "TRUE", "d" => 1)).to eq(false)
    expect(validator.get_errors).to eq(
      "a" => "NOT_ALLOWED_VALUE", "b" => "NOT_ALLOWED_VALUE", "c" => "NOT_ALLOWED_VALUE", "d" => "NOT_ALLOWED_VALUE"
    )
  end

  it "iso_date and iso_datetime use the proleptic Gregorian calendar" do
    validator = LIVR::Validator.new(
      "date1" => "iso_date",
      "date2" => { "iso_date" => {} },
      "date3" => { "iso_date" => { "min" => "1582-10-10" } },
      "starts_at" => "iso_datetime"
    )

    # Not the Julian calendar before 1582-10-15: 1582-10-10 is a date, 1500-02-29 is not
    expect(validator.validate("date1" => "1582-10-10", "date2" => "1582-10-10", "date3" => "1582-10-10",
                              "starts_at" => "1582-10-10T00:00Z")).to eq(
      "date1" => "1582-10-10", "date2" => "1582-10-10", "date3" => "1582-10-10", "starts_at" => "1582-10-10T00:00:00.000Z"
    )

    expect(validator.validate("date1" => "1500-02-29", "date2" => "1500-02-29", "date3" => "1582-10-09",
                              "starts_at" => "1500-02-29T00:00Z")).to eq(false)
    expect(validator.get_errors).to eq(
      "date1" => "WRONG_DATE", "date2" => "WRONG_DATE", "date3" => "DATE_TOO_EARLY", "starts_at" => "WRONG_DATETIME"
    )
    expect { LIVR::Validator.new("date" => { "iso_date" => { "min" => "1500-02-29" } }).prepare }.to raise_error(RuntimeError)
  end

  it "url: labels have at most 63 characters of any letters, the scheme and localhost are in any case" do
    validator = LIVR::Validator.new("label" => "url", "tld" => "url", "unicode" => "url", "upper" => "url", "localhost" => "url")

    valid = {
      "label"     => "https://#{'s' * 63}.example.com/",
      "tld"       => "https://example.#{'f' * 63}",
      "unicode"   => "https://straße.de/",
      "upper"     => "HTTPS://WWW.EXAMPLE.COM:8/",
      "localhost" => "Http://LocalHost:65535"
    }
    expect(validator.validate(valid)).to eq(valid)

    # "ss" and "ff" are two letters, not one (ß, ﬀ)
    expect(validator.validate("label" => "https://#{'s' * 64}.example.com/", "tld" => "https://example.#{'f' * 64}",
                              "upper" => "HTTPS://WWW.EXAMPLE.COM.")).to eq(false)
    expect(validator.get_errors).to eq("label" => "WRONG_URL", "tld" => "WRONG_URL", "upper" => "WRONG_URL")
  end

  it "unique with keys: an object or a list as a key value is a format error, also next to an empty key value" do
    validator = LIVR::Validator.new("items" => { "unique" => ["id", "name"] })

    expect(validator.validate("items" => [{ "id" => "", "name" => { "a" => 1 } }])).to eq(false)
    expect(validator.get_errors).to eq("items" => "FORMAT_ERROR")
    expect(validator.validate("items" => [{ "id" => [1], "name" => nil }])).to eq(false)
    expect(validator.get_errors).to eq("items" => "FORMAT_ERROR")
  end
end
