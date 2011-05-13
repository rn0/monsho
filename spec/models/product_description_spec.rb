require 'spec_helper'

describe ProductDescription do
  it { should_not have_valid(:name).when('', nil) }
  it { should_not have_valid(:value).when('', nil) }
  it { should_not have_valid(:type).when('', nil, 'unknown type') }
  it { should have_valid(:type).when('varchar', 'float', 'int', 'bit') }

  describe 'before save' do
    it 'should create slug' do
      d = Factory.build(:product_description, :name => 'Test description')
      d.run_callbacks(:save)
      d.slug.should == 'test-description'
    end
  end
end
