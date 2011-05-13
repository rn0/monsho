require 'spec_helper'

describe ProductDescription do
  it { should_not have_valid(:name).when('', nil) }
  it { should_not have_valid(:value).when('', nil) }
  it { should_not have_valid(:type).when('', nil, 'unknown type') }
  it { should have_valid(:type).when('varchar', 'float', 'int', 'bit') }

  describe 'before save' do
    it 'should create slug' do
      @p = Product.new
      @p.description.create!({ name: 'test description', value: 'test value', type: 'varchar' })
      @p.description.first.slug.should == 'test-description'
    end
  end
end
