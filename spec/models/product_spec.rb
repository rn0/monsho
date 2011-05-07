require 'spec_helper'

describe Product do
  describe 'Validations' do
    it { should have_valid(:price).when(1.0, 0.9) }
    it { should_not have_valid(:price).when(-1, 0, 'a') }

    it { should have_valid(:net_price).when(1.0, 0.9) }
    it { should_not have_valid(:net_price).when(-1, 0, 'a') }
  end
end