$: << (File.dirname(__FILE__) + "/../lib")

require 'complexid'

describe Oatmeal::Complexid do
  before :each do
    @c = Oatmeal::Complexid.new(File.dirname(__FILE__) + "/../../../db/dev.yml")
  end

  it 'should initialize properly' do
    @c.should_not be_nil
  end

end
