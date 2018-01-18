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

end