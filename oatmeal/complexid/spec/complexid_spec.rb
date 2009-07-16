$: << (File.dirname(__FILE__) + "/../lib")

# ActiveRecord environment location
ENV_FILE = File.dirname(__FILE__) + "/../../../db/env.yml"
# beanstalkd queue location
TEST_QUEUE = ['localhost:11300']

SPEC_FILE_DIR = File.dirname(__FILE__) + "/spec_files"
SPEC_EXAMPLE_BASE = "a"
SPEC_EXAMPLE_FILE = "./a.rb"
KNOWN_STATS = [SPEC_EXAMPLE_FILE, "0.570645834224529", "0.586986749301636", "3.40291187981663", "3.70043971814109", "22"]
# Example url for checking out code
SPEC_URL = "git://github.com/dakrone/ricepaper.git"
BEANSTALK_URL = "localhost:11300"

require 'gitobjects'
require 'complexid'
require 'tmpdir'
require 'yaml'
require 'beanstalk-client'

describe Oatmeal::Repository do
  before :each do
    @gr = Oatmeal::Repository.new(SPEC_URL)
  end

  it 'should correctly parse the url, username and project name' do
    @gr.url.should == SPEC_URL
    @gr.user.should == 'dakrone'
    @gr.project.should == 'ricepaper'
    @gr.project_dir.should =~ /git-storage\/dakrone\/ricepaper/
  end

  it 'should check out the project from git' do
    repo = @gr.clone(Dir.tmpdir)
    repo.should_not be_nil
    File.exist?(Dir.tmpdir + "/dakrone").should be_true
    File.exist?(Dir.tmpdir + "/dakrone/ricepaper").should be_true
  end
end

describe Oatmeal::Complexid do
  before :each do
    @c = Oatmeal::Complexid.new(YAML::load(File.open(ENV_FILE))['test'], BEANSTALK_URL)
  end

  it 'should initialize properly' do
    @c.should_not be_nil
  end

  it 'should process a directory of files and return a Hash' do
    @c.process_directory(SPEC_FILE_DIR).should be_instance_of(Hash)
  end

  it 'should be able process a url from checkout to statistics' do
    # Add our spec url to the queue
    b = Beanstalk::Pool.new([BEANSTALK_URL])
    b.put(SPEC_URL)

    @c.start
    @c.stop
    @c.statistics.should_not be_empty
  end

  it 'should return the known statistics about a.rb' do
    stats = @c.process_directory(SPEC_FILE_DIR)[SPEC_EXAMPLE_BASE][0]
    stats[0].should == KNOWN_STATS[0]
    stats[1].to_s.should == KNOWN_STATS[1]
    stats[2].to_s.should == KNOWN_STATS[2]
    stats[3].to_s.should == KNOWN_STATS[3]
    stats[4].to_s.should == KNOWN_STATS[4]
  end

  it 'should fetch work items out of the queue'

  it 'should put the results in the database' do
    @c.process_directory(SPEC_FILE_DIR)
    @c.push_stats.should be_true
  end

  it 'should start and stop without a problem' do
    @c.start
    @c.running?.should be_true
    @c.stop
    @c.running?.should be_false
  end

end
