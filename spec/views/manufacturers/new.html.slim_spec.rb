require 'spec_helper'

describe "manufacturers/new.html.slim" do
  before(:each) do
    assign(:manufacturer, stub_model(Manufacturer).as_new_record)
  end

  it "renders new manufacturer form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => manufacturers_path, :method => "post" do
    end
  end
end
