require 'spec_helper'

describe User do
  it { should have_valid(:email).when('test@example.com', 'test+friends@gmail.com', 'test.test@example.com') }
  it { should_not have_valid(:email).when('', ' ', nil, 'test@example') }

  it { should have_valid(:password).when('123456') }
  it { should_not have_valid(:password).when('', nil, '1234', ' ') }

  it "should reject duplicate email" do
    args = Factory.attributes_for :user
    
    u1 = User.create! args
    u1.should be_valid

    u2 = User.new args
    u2.should_not be_valid
  end
end