# encoding:utf-8

describe "An Encoding node" do
  parse "__ENCODING__" do
    [:encoding, "UTF-8"]
  end
end
