class Drops::FeedBufferController < ApplicationController
  def index
    @store = DropStorage.find_or_create_by(name: :feed_buffer)

    @interval = params[:interval].to_i.minutes

    feed = open(params[:feed_url]).read
    @feed_doc = Nokogiri::XML(feed)

    render plain: <<-FEED
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
  <title>Сергей Удалов / diggs</title>
  <description></description>

    #{published_items.join}
</channel>
    FEED

    published!
  end

  private

  def published_items
    if last_published_at.blank?
      [items.sort_by(&:published_at).first]
    elsif need_more_items?
      [items.sort_by(&:published_at).second]
    else
      [items.sort_by(&:published_at).first]
    end
  end

  def need_more_items?
    last_published_at <= @interval.ago
  end

  def last_published_at
    @store.read(:last_published_at)
  end

  def published!
    @store.write(:last_published_at, Time.now)
    @store.write(:last_published_item_id, published_items.sort_by(&:published_at).last.guid)
  end

  class FeedItem
    def initialize(doc)
      @doc = doc
    end

    def published_at
      Time.parse @doc.css('pubDate').to_s
    end

    def guid
      @doc.css('link').to_s
    end

    def to_s
      @doc.to_xml
    end
  end

  def items
    @feed_doc.css('item').map { |item| FeedItem.new(item) }
  end
end
