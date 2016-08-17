class Drops::FeedBufferController < ApplicationController
  def index
    feed = open(params[:feed_url]).read
    @feed_doc = Nokogiri::XML(feed)

    render plain: <<-FEED
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
  <title>Сергей Удалов / diggs</title>
  <description></description>

  #{items}
</channel>
    FEED
  end

  private

  def items
    @feed_doc.css('item').first
  end
end
