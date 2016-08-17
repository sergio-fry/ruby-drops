require 'rails_helper'

RSpec.describe 'FeedBuffers', type: :request do
  describe 'GET /feed_buffers' do
    let(:feed_url) { 'http://example.com/feed' }

    before do
      stub_request(:get, feed_url)
        .to_return(status: 200, body: File.open(Rails.root.join('spec/files/diggs.rss')).read)

      get '/drops/feed_buffer', params: { feed_url: feed_url }
    end

    it 'works!' do
      expect(response).to have_http_status(200)
    end

    describe '@items' do
      subject { Nokogiri::XML(@response.body).css('item') }
      it { is_expected.to be_present }
      its(:size) { is_expected.to eq 1 }
    end
  end
end
