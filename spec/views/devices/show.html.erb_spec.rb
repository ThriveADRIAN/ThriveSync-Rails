require 'rails_helper'

RSpec.describe "devices/show", type: :view do
  before(:each) do
    @device = assign(:device, Device.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
