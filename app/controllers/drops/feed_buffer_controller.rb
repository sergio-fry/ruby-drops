class Drops::FeedBufferController < ApplicationController
  def index
    publish_next_item if need_more_items?

    @items = published_items

    respond_to do |format|
      format.atom
    end

    update_stats!
  end

  private

  def published_items
    items[last_published_index..-1]
  end

  class FeedItem
    attr_reader :title, :content, :url

    def initialize(title:, content:, url:)
      @title, @content, @url = title, content, url
    end

    def guid
      @url
    end

    def to_s
      {
        title: title,
        content: content,
        url: url
      }.to_json
    end
  end

  class FeedItemXml
    def initialize(doc)
      @doc = doc
    end

    def published
      1.hour.ago
    end

    def id
      guid
    end

    def url
      @doc.css('link').text
    end

    def title
      @doc.css('title').text
    end

    def content
      @doc.css('description').text
    end

    def guid
      url
    end

    def to_s
      @doc.css('guid')[0].content = guid
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
    store.write(:last_published_item_guid, published_items.first.guid)
  end

  def items
    feed_doc.css('item').map { |item| FeedItemXml.new(item) }
  end

  def feed
    @feed ||= Feedjira::Feed.parse feed_body
  end

  def feed_doc
    Nokogiri::XML(feed_body)
  end

  def feed_body
    Rails.cache.fetch("FeedBufferController:#{script_id}", expires_in: expires_in) do
      Faraday.get(feed_body).body
    end
  end

  def expires_in
    [interval.to_f / 2, 1].max.minutes
  end

  def feed_url
    params[:feed_url]
  end

  def store
    @store ||= DropStorage.find_or_create_by(name: "feed_buffer_#{script_id}")
  end

  def script_id
    Digest::SHA256.hexdigest "#{feed_url}##{interval}"
  end

  def interval
    params[:interval].to_i.minutes
  end

  def publish_next_item
    return if next_item.blank?

    store.write(:last_published_at, Time.now)
    store.write(:last_published_item_guid, next_item.guid)
  end

  def feed_title
    feed_doc.css('title').first.text
  end
end
