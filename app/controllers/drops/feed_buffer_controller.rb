class Drops::FeedBufferController < ApplicationController
  def index
    @store = DropStorage.find_or_create_by(name: :feed_buffer)

    feed = open(params[:feed_url]).read
    @feed_doc = Nokogiri::XML(feed)

    render plain: <<-FEED
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
  <title>Сергей Удалов / diggs</title>
  <description></description>

  #{published_items}
</channel>
    FEED
  end

  private

  def published_items
    items.first
  end

  def most_recent_published_at
  end

  def items
    @feed_doc.css('item')
  end
end
