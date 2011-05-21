require 'spec_helper'

describe Search do
  describe 'validation' do
    it { should have_valid(:query).when('athlon', 'test test') }
    it { should_not have_valid(:query).when(nil, '', ' ') }
  end

  describe '#get' do

    context 'when a search dont exist' do
      before do
        @doc = Search.get('random query 1')
      end

      it 'should create new document' do
        expect {
          @doc.save!
        }.to change { Search.count }.by(1)
      end

      it 'should have 0 hits' do
        @doc.hits.should == 0
      end
    end
    
    context 'when a search exist' do
      before do
        Search.get('random query').save!
        @doc2 = Search.get('random query')
      end

      it 'should not save duplicate' do
        expect {
          @doc2.save
        }.to change { Search.count }.by(0)
      end

      it 'should increase hits counter' do
        @doc2.hits.should == 1
      end
    end
  end
end
