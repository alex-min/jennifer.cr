require "../spec_helper"

describe Jennifer::Validations::Exclusion do
  described_class = Jennifer::Validations::Exclusion

  describe "#validate" do
    describe "String" do
      it { validated_by_record({collection: ["Sam"]}, "John", :name).should_not be_invalid }
      it { validated_by_record({collection: ["Sam"]}, "Sam", :name).should be_invalid }
      it { validated_by_record({collection: ["Sam"]}, nil, :name).should_not be_invalid }
    end

    describe "Float32" do
      it { validated_by_record({collection: [1.2]}, 2.5, :name).should_not be_invalid }
      it { validated_by_record({collection: [1.2]}, 1.2, :name).should be_invalid }
      it { validated_by_record({collection: [1.2]}, nil, :name).should_not be_invalid }
    end

    describe "Int32" do
      it { validated_by_record({collection: [1]}, 2, :name).should_not be_invalid }
      it { validated_by_record({collection: [1]}, 1, :name).should be_invalid }
      it { validated_by_record({collection: [1]}, nil, :name).should_not be_invalid }
    end
  end

  pending "test allow_blank"
end
