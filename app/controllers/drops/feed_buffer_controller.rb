class Drops::FeedBufferController < ApplicationController
  def index
    publish_next_item if need_more_items?

    render plain: <<-FEED
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
  <title>#{feed_title}</title>
  <description></description>

    #{published_items.join}
</channel>
    FEED

    update_stats!
  end

  private

  def published_items
    items[last_published_index..-1]
  end

  class FeedItem
    def initialize(doc)
      @doc = doc
    end

    def title
      @doc.css('title').text
    end

    def guid
      @doc.css('link').text
    end

    def to_s
      @doc.to_xml
    end
  end

  def next_item
    if no_new_items_since_last_publish?
      nil
    elsif last_published_not_found_in_a_feed? 
      items.last
    else
      items[last_published_index - 1]
    end
  end

  def last_published_not_found_in_a_feed?
    last_published_index.nil?
  end

  def no_new_items_since_last_publish?
    last_published_index == 0
  end

  def last_published_index
    items.map(&:guid).index store.read(:last_published_item_guid)
  end

  def need_more_items?
    last_published_at.blank? || (last_published_at <= interval.ago)
  end

  def last_published_at
    store.read(:last_published_at)
  end

  def update_stats!
    store.write(:last_published_at, Time.now)
    store.write(:last_published_item_guid, published_items.first.guid)
  end

  def items
    feed_doc.css('item').map { |item| FeedItem.new(item) }
  end

  def feed_doc
    Nokogiri::XML(feed_body)
  end

  def feed_body
    Rails.cache.fetch("FeedBufferController:#{feed_url}", expires_in: (interval / 2).minutes) do
      open(feed_url).read
    end
  end

  def feed_url
    params[:feed_url]
  end

  def store
    @store ||= DropStorage.find_or_create_by(name: "feed_buffer_#{feed_url_hash}")
  end

  def feed_url_hash
    Digest::SHA256.hexdigest feed_url
  end

  def interval
    params[:interval].to_i.minutes
  end

  def publish_next_item
    return if next_item.blank?
    store.write(:last_published_item_guid, next_item.guid)
  end

  def feed_title
    feed_doc.css('title').text
  end
end
