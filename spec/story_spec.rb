require 'spec_helper'

describe Scheherazade::Story do
  describe 'tell' do
    let(:tell) do
      story.tell(options) do
        page = Page.imagine
        story.current[Page].should == page
        page
      end
    end

    let(:wont_change_the_story) do
      tell
      story.current[Page].should be_nil
      story.current[Website].should be_nil
    end

    context 'without rollback' do
      let(:options) { {:rollback => false} }

      it { wont_change_the_story }

      it "will keep created records around" do
        p = tell
        Page.find_by_id(p.id).should == p
        Website.all.should == [p.website]
      end
    end

    context 'with rollback' do
      let(:options) { {:rollback => true} }

      it { wont_change_the_story }

      it "destroys created records" do
        p = tell
        Page.find_by_id(p.id).should be_nil
        Website.all.should be_empty
      end
    end

    it 'is thread-safe' do
      cur = story
      s = nil
      t = Thread.new do
        cur.should_not == story
        story.tell do
          s = story
          sleep
        end
      end
      story.tell do
        t.join(0.01) until s
        s.should_not == cur
        s.should_not == cur
      end
      t.kill
    end
  end

  describe '==' do
    it 'is true only for the same story object' do
      story.should == story
      Scheherazade::Story.new.should_not == Scheherazade::Story.new
      Scheherazade::Story.new.should_not eql Scheherazade::Story.new
    end
  end

  [[Page, :page], [:page, Page]].each do |char, equiv|
    it "does not distinguish between #{char} and #{equiv}" do
      p = story.imagine(char)
      p.should == story.current[equiv]
      p.should == story.get(equiv)
      end
  end
end
