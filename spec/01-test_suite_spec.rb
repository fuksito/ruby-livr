require 'spec_helper.rb'
require 'active_support/testing/time_helpers'

def read_file(dir, filename)
  data = File.read dir.join("#{filename}.json")
  JSON.parse(data)
end

def read_aliases(dir)
  dir.join("aliases.json").exist? ? read_file(dir, "aliases") : []
end

def build_validator(dir)
  validator = LIVR::Validator.new(read_file(dir, "rules"))
  read_aliases(dir).each { |_alias| validator.register_aliased_rule(_alias) }
  validator
end

# test_suite is LIVR 2.0, test_suite_2.5 the rules added in LIVR 2.5
%w[ test_suite test_suite_2.5 ].each do |suite|
  RSpec.describe "#{suite} " do
    # options.json: {"now": "2026-10-18T12:00:00Z"} is the current time for "today", "yesterday" and "tomorrow"
    include ActiveSupport::Testing::TimeHelpers

    %w[ positive negative aliases_positive aliases_negative ].each do |spec_dir|
      context spec_dir do
        dirs = Pathname.new("#{SPEC_ROOT}/#{suite}/#{spec_dir}").children.select(&:directory?).sort
        dirs.each do |dir|
          it dir.basename do
            validator = build_validator(dir)
            input = read_file(dir, "input")

            options = dir.join("options.json").exist? ? read_file(dir, "options") : {}
            result = if options["now"]
              travel_to(Time.iso8601(options["now"])) { validator.validate(input) }
            else
              validator.validate(input)
            end
            errors = validator.get_errors

            if spec_dir.end_with?('positive')
              expected_result = read_file(dir, "output")
              expect(result).to eq(expected_result)
            else
              expected_errors = read_file(dir, "errors")
              expect(errors).to eq(expected_errors)
            end
          end
        end
      end
    end

    schema_errors_dir = Pathname.new("#{SPEC_ROOT}/#{suite}/schema_errors")
    next unless schema_errors_dir.exist?

    context "schema_errors" do
      schema_errors_dir.children.select(&:directory?).sort.each do |dir|
        it dir.basename do
          expect { build_validator(dir).prepare }.to raise_error(StandardError)
        end
      end
    end
  end
end
