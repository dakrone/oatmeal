$: << (File.dirname(__FILE__) + "/../lib")

SPEC_FILE_DIR = File.dirname(__FILE__) + "/spec_files"
SPEC_EXAMPLE_BASE = "a"
SPEC_EXAMPLE_FILE = "./a.rb"
KNOWN_STATS = [SPEC_EXAMPLE_FILE, "0.570645834224529", "0.586986749301636", "3.40291187981663", "3.70043971814109", "22"]
SPEC_URL = "git://github.com/dakrone/ricepaper.git"

require 'complexid'
require 'tmpdir'

describe Oatmeal::GitRepo do
  before :each do
    @gr = Oatmeal::GitRepo.new(SPEC_URL)
  end

  it 'should correctly parse the url, username and project name' do
    @gr.url.should == SPEC_URL
    @gr.user.should == 'dakrone'
    @gr.project.should == 'ricepaper'
  end

  it 'should check out the project from git' do
    repo = @gr.clone(Dir.tmpdir)
    repo.should_not be_nil
  end
end

describe Oatmeal::Complexid do
  before :each do
    @c = Oatmeal::Complexid.new(File.dirname(__FILE__) + "/../../../db/env.yml")
  end

  it 'should initialize properly' do
    @c.should_not be_nil
  end

  it 'should process a directory of files and return a Hash' do
    @c.process_directory(SPEC_FILE_DIR).should be_instance_of(Hash)
  end

  it 'should return the known statistics about a.rb' do
    stats = @c.process_directory(SPEC_FILE_DIR)[SPEC_EXAMPLE_BASE][0]
    stats[0].should == KNOWN_STATS[0]
    stats[1].to_s.should == KNOWN_STATS[1]
    stats[2].to_s.should == KNOWN_STATS[2]
    stats[3].to_s.should == KNOWN_STATS[3]
    stats[4].to_s.should == KNOWN_STATS[4]
  end

  it 'should check out the latest git commit given a url' do
    loc = @c.git_checkout_url(SPEC_URL)
    loc.should_not be_nil
  end

  it 'should fetch work items out of the queue'

  it 'should put the results in the database'

end
