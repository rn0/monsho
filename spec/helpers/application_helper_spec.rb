describe ApplicationHelper do
  describe 'link_to_category' do
    let(:category) do
      Factory(:category, :name => 'test')
    end

    it 'should return well formatted html' do
      category.stub_chain(:stats, :active_products).and_return(0)
      link = %{<a href="/categories/#{category.id}">test <span>(0)</span></a>}
      helper.link_to_category(category).should == link
    end

    context 'nil values' do
      it 'should handle nil category' do
        helper.link_to_category(nil).should be_nil
      end
      
      it 'should handle nil stats' do
        link = %{<a href="/categories/#{category.id}">test <span>(-)</span></a>}
        helper.link_to_category(category).should == link
      end

      it 'should handle nil category name' do
        category.name = nil
        helper.link_to_category(category).should be_nil
      end
    end
  end
end