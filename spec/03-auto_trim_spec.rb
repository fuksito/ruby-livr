require 'spec_helper.rb'

RSpec.describe "auto_trim" do

  let(:validator) do
    LIVR::Validator.new({
      code: "required",
      password: [ "required", { "min_length" => 3 }],
      address:  { "nested_object" => {
          street: { "min_length" => 5 },
        }
      }
    }, true)
  end

  it "NEGATIVE: Validate data with automatic trim" do
    output = validator.validate({
        code: '  ',
        password: ' 12  ',
        address: {
            street: '  hell '
        }
      })
    # expect(output).to eq(false), 'should return false due to validation errors fot trimmed values'
    expect(output).to eq(false)

    expect(validator.get_errors).to eq({
                                        code: 'REQUIRED',
                                        password: 'TOO_SHORT',
                                        address: {
                                          street: 'TOO_SHORT',
                                        }
                                      })

  end

  it "POSITIVE: Validate data with automatic trim" do
    clean_data = validator.validate({
        code: ' A ',
        password: ' 123  ',
        address: {
            street: '  hello '
        }
    })

    expect(clean_data).to be_truthy, 'should return clean data'
    expect(clean_data).to eq({
                              code: 'A',
                              password: '123',
                              address: {
                                street: 'hello',
                              }
                             }), 'Should contain error codes'
  end

end
