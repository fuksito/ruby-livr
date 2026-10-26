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

end
