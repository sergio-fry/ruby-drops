require 'rails_helper'

RSpec.describe 'FeedBuffers', type: :request do
  describe 'GET /feed_buffers' do
    let(:feed_url) { 'http://example.com/feed' }
    let(:interval) { 10 }

    before do
      stub_request(:get, feed_url)
        .to_return(status: 200, body: File.open(Rails.root.join('spec/files/diggs.rss')).read)

      get '/drops/feed_buffer', params: { feed_url: feed_url, interval: 10 }
    end

    it 'works!' do
      expect(response).to have_http_status(200)
    end

    describe '@items' do
      subject(:items) { Nokogiri::XML(@response.body).css('item') }
      it { is_expected.to be_present }
      its(:size) { is_expected.to eq 1 }

      describe 'most resecent published item' do
        subject(:item) { items.first }

        it 'should be the oldest one' do
          expect(item.css('title').text).to eq '2 Hours ago'
        end

        it { expect(items.size).to eq 1 }

        context '9 minutes later' do
          before do
            Timecop.travel 9.minutes.from_now
          end

          after { Timecop.return }

          it 'should be the oldest one' do
            get '/drops/feed_buffer', params: { feed_url: feed_url, interval: 10 }
            expect(item.css('title').text).to eq '2 Hours ago'
            expect(items.size).to eq 1
          end
        end

        context '11 minutes later' do
          before do
            Timecop.travel 11.minutes.from_now
            get '/drops/feed_buffer', params: { feed_url: feed_url, interval: 10 }
          end

          after { Timecop.return }

          it 'should be fresh item' do
            expect(item.css('title').text).to eq '1 Hour ago'
            expect(items.size).to eq 2
          end

          context '11 minutes after' do
            before do
              Timecop.travel 22.minutes.from_now
              get '/drops/feed_buffer', params: { feed_url: feed_url, interval: 10 }
            end

            after { Timecop.return }

            it 'should stay the same' do
              expect(item.css('title').text).to eq '1 Hour ago'
              expect(items.size).to eq 2
            end
          end
        end
      end
    end
  end
end
