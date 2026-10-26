require 'spec_helper.rb'

RSpec.describe "primitive values" do

  it "iso_date: numbers and booleans are wrong dates" do
    validator = LIVR::Validator.new(
      "date1" => "iso_date",
      "date2" => "iso_date",
      "date3" => "iso_date"
    )

    output = validator.validate("date1" => 20200101, "date2" => 1.5, "date3" => true)

    expect(output).to eq(false)
    expect(validator.get_errors).to eq(
      "date1" => "WRONG_DATE",
      "date2" => "WRONG_DATE",
      "date3" => "WRONG_DATE"
    )
  end

  it "iso_date: only YYYY-MM-DD strings are dates" do
    validator = LIVR::Validator.new(
      "date1" => "iso_date",
      "date2" => "iso_date",
      "date3" => "iso_date",
      "date4" => "iso_date"
    )

    output = validator.validate("date1" => "2020-01-1x", "date2" => "+020-01-01", "date3" => "2020-1-1-1", "date4" => "2020-01-01")

    expect(output).to eq(false)
    expect(validator.get_errors).to eq(
      "date1" => "WRONG_DATE",
      "date2" => "WRONG_DATE",
      "date3" => "WRONG_DATE"
    )
  end

  it "integer, positive_integer: strings are decimal numbers" do
    validator = LIVR::Validator.new(
      "int1" => "integer",
      "int2" => "positive_integer",
      "int3" => "positive_integer"
    )

    output = validator.validate("int1" => "010", "int2" => "09", "int3" => "0x10")

    expect(output).to eq(false)
    expect(validator.get_errors).to eq("int3" => "NOT_POSITIVE_INTEGER")

    expect(validator.validate("int1" => "010", "int2" => "09")).to eq("int1" => 10, "int2" => 9)
  end

  it "numeric rules: underscores are not digits" do
    validator = LIVR::Validator.new(
      "number1" => "integer",
      "number2" => "positive_integer",
      "number3" => { "min_number" => 1 },
      "number4" => { "number_between" => [1, 2000] }
    )

    output = validator.validate("number1" => "1_000", "number2" => "1_000", "number3" => "1_000", "number4" => "1_000.5")

    expect(output).to eq(false)
    expect(validator.get_errors).to eq(
      "number1" => "NOT_INTEGER",
      "number2" => "NOT_POSITIVE_INTEGER",
      "number3" => "NOT_NUMBER",
      "number4" => "NOT_NUMBER"
    )
  end

  it "min_number, max_number, number_between: integers stay integers" do
    validator = LIVR::Validator.new(
      "number1" => { "min_number" => 18 },
      "number2" => { "max_number" => 100 },
      "number3" => { "number_between" => [1, 100] },
      "number4" => { "number_between" => [1, 100] }
    )

    output = validator.validate("number1" => 32, "number2" => "33", "number3" => "35", "number4" => "1.5")

    expect(output.values.map(&:class)).to eq([Integer, Integer, Integer, Float])
    expect(output).to eq("number1" => 32, "number2" => 33, "number3" => 35, "number4" => 1.5)
  end

  it "modifiers return strings to the next rules" do
    validator = LIVR::Validator.new(
      "email" => [ "required", "trim", "email", "to_lc" ],
      "code"  => [ "to_uc", { "one_of" => ["ABC"] } ],
      "phone" => [ { "leave_only" => "0123456789" }, { "max_length" => 5 } ],
      "name"  => [ { "remove" => "-" }, "string" ]
    )

    output = validator.validate(
      "email" => " User@Example.com ",
      "code"  => "abc",
      "phone" => "12-34",
      "name"  => "a-b"
    )

    expect(output).to eq("email" => "user@example.com", "code" => "ABC", "phone" => "1234", "name" => "ab")
    expect(output.values.map(&:class).uniq).to eq([String])
  end

  it "modifiers pass lists through unchanged" do
    validator = LIVR::Validator.new(
      "list1" => "trim",
      "list2" => "to_lc",
      "list3" => "to_uc",
      "list4" => { "remove" => "1" },
      "list5" => { "leave_only" => "1" }
    )

    input = { "list1" => [" a "], "list2" => ["A"], "list3" => ["a"], "list4" => [1, 2], "list5" => [1, 2] }

    expect(validator.validate(input)).to eq(input)
  end

  it "required: false, 0 and whitespace are values" do
    validator = LIVR::Validator.new(
      "field1" => "required",
      "field2" => "required",
      "field3" => "required"
    )

    output = validator.validate("field1" => false, "field2" => 0, "field3" => " ")

    expect(output).to eq("field1" => false, "field2" => 0, "field3" => " ")
  end

end
