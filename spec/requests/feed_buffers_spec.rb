require 'rails_helper'

RSpec.describe 'FeedBuffers', type: :request do
  describe 'GET /feed_buffers' do
    let(:feed_url) { 'http://example.com/feed' }
    let(:interval) { 10 }

    def send_request
      get '/drops/feed_buffer', params: { feed_url: feed_url, interval: 10, format: :atom }
    end

    before do
      stub_request(:get, feed_url)
        .to_return(status: 200, body: File.open(Rails.root.join('spec/files/diggs.rss')).read)

      send_request
    end

    it 'works!' do
      expect(response).to have_http_status(200)
    end

    describe '@items' do
      subject(:items) { Feedjira::Feed.parse(@response.body).entries }
      it { is_expected.to be_present }
      its(:size) { is_expected.to eq 1 }

      describe 'most resecent published item' do
        subject(:item) { items.first }

        it 'should be the oldest one' do
          expect(item.title).to eq '2 Hours ago'
        end

        it 'should have a link as guid' do
          expect(item.id).to eq 'https://politics.dirty.ru/comments/1153199'
        end

        it { expect(items.size).to eq 1 }

        context '9 minutes later' do
          before do
            Timecop.travel 9.minutes.from_now
          end

          after { Timecop.return }

          it 'should be the oldest one' do
            send_request
            expect(item.title).to eq '2 Hours ago'
            expect(items.size).to eq 1
          end
        end

        context '11 minutes later' do
          before do
            Timecop.travel 11.minutes.from_now
            send_request
          end

          after { Timecop.return }

          it 'should be fresh item' do
            expect(item.title).to eq '1 Hour ago'
            expect(items.size).to eq 2
          end

          context '11 minutes after' do
            before do
              Timecop.travel 22.minutes.from_now
              send_request
            end

            after { Timecop.return }

            it 'should stay the same' do
              expect(item.title).to eq '1 Hour ago'
              expect(items.size).to eq 2
            end
          end
        end
      end
    end
  end
end
