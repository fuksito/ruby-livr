require 'spec_helper.rb'

RSpec.describe "aliases" do

  it "Validates with aliased rules" do
    validator = LIVR::Validator.new({
        "password" => ["required", "strong_password"]
      })
    validator.register_aliased_rule({
      "name" => 'strong_password',
      "rules" => { "min_length" => 6 },
      "error" => 'WEAK_PASSWORD'
    })


    output = validator.validate({ "password" => "abc" })
    expect(output).to eq(false)
    expect(validator.get_errors).to eq({"password" => "WEAK_PASSWORD"})
  end

  it "Validates with aliases and custom rules inside meta rules" do
    weak_password = Class.new(LIVR::Rule) do
      def call(value, user_data, field_results)
        "WEAK_PASSWORD" if value.to_s.length < 6
      end
    end

    validator = LIVR::Validator.new({
      "user"      => "user",
      "passwords" => { "list_of" => "weak_password" }
    })
    validator.register_aliased_rule({
      "name"  => "user",
      "rules" => { "nested_object" => { "age" => "adult_age" } }
    })
    validator.register_aliased_rule({
      "name"  => "adult_age",
      "rules" => [ "positive_integer", { "min_number" => 18 } ]
    })
    validator.register_rules("weak_password" => weak_password)

    output = validator.validate({ "user" => { "age" => 10 }, "passwords" => [ "abc", "abcdefg" ] })
    expect(output).to eq(false)
    expect(validator.get_errors).to eq({
      "user"      => { "age" => "TOO_LOW" },
      "passwords" => [ "WEAK_PASSWORD", nil ]
    })
  end

end
