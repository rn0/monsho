require "spec_helper"

describe ManufacturersController do
  describe "routing" do

    it "routes to #index" do
      get("/manufacturers").should route_to("manufacturers#index")
    end

    it "routes to #new" do
      get("/manufacturers/new").should route_to("manufacturers#new")
    end

    it "routes to #show" do
      get("/manufacturers/1").should route_to("manufacturers#show", :id => "1")
    end

    it "routes to #edit" do
      get("/manufacturers/1/edit").should route_to("manufacturers#edit", :id => "1")
    end

    it "routes to #create" do
      post("/manufacturers").should route_to("manufacturers#create")
    end

    it "routes to #update" do
      put("/manufacturers/1").should route_to("manufacturers#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/manufacturers/1").should route_to("manufacturers#destroy", :id => "1")
    end

  end
end
