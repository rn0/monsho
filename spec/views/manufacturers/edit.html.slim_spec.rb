require 'spec_helper'

describe "manufacturers/edit.html.slim" do
  before(:each) do
    @manufacturer = assign(:manufacturer, stub_model(Manufacturer))
  end

  it "renders the edit manufacturer form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => manufacturers_path(@manufacturer), :method => "post" do
    end
  end
end
