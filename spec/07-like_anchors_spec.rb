require 'spec_helper.rb'

RSpec.describe "like" do

  it "^ and $ anchor the whole value, not a line" do
    validator = LIVR::Validator.new(
      "zip1" => { "like" => "^[0-9]{5}$" },
      "zip2" => { "like" => "^[0-9]{5}$" },
      "zip3" => { "like" => "^[0-9]{5}$" },
      "zip4" => { "like" => ["^[0-9]{5}$", "i"] },
      "zip5" => { "like" => "^[0-9]{5}$" }
    )

    output = validator.validate(
      "zip1" => "12345\n<script>",
      "zip2" => "<script>\n12345",
      "zip3" => "12345\n",
      "zip4" => "12345\n<script>",
      "zip5" => "12345"
    )

    expect(output).to eq(false)
    expect(validator.get_errors).to eq(
      "zip1" => "WRONG_FORMAT",
      "zip2" => "WRONG_FORMAT",
      "zip3" => "WRONG_FORMAT",
      "zip4" => "WRONG_FORMAT"
    )
  end

  it "^ and $ in character classes and escaped ones stay literal" do
    validator = LIVR::Validator.new(
      "price"   => { "like" => "^\\$[0-9]+$" },
      "caret"   => { "like" => "^[\\^$]+$" },
      "negated" => { "like" => "^[^0-9]+$" },
      "bracket" => { "like" => "^[]^$]+$" }
    )

    output = validator.validate("price" => "$10", "caret" => "^$^", "negated" => "abc", "bracket" => "]^$")

    expect(validator.get_errors).to eq(nil)
    expect(output).to eq("price" => "$10", "caret" => "^$^", "negated" => "abc", "bracket" => "]^$")
  end

  it "patterns without anchors still match part of the value" do
    validator = LIVR::Validator.new("name" => { "like" => "[0-9]+" })

    expect(validator.validate("name" => "abc\n123")).to eq("name" => "abc\n123")
  end
end
