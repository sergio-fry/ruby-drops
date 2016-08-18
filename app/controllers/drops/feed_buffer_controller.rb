class Drops::FeedBufferController < ApplicationController
  def index
    push_new_items_into_queue
    publish_next_item

    render plain: <<-FEED
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
  <title>#{feed_title}</title>
  <description></description>

    #{published_items_list.all.reverse.join}
</channel>
    FEED

    update_stats!
  end

  private

  class FeedItem
    def initialize(doc)
      @doc = doc
    end

    def guid
      @doc.css('link').text
    end

    def to_s
      @doc.to_xml
    end
  end

  class ItemsList
    def initialize(store, name)
      @store = store
      @name = name
    end

    def push(item)
      list.push serialize(item)
      save
    end

    def pop
      res = deserialize list.shift
      save

      res
    end

    def last
      deserialize list.last
    end

    def all
      list.map { |it| deserialize(it) }
    end

    def include?(item)
      all.map(&:guid).include? item.guid
    end

    private

    def serialize(item)
      item.to_s
    end

    def deserialize(str)
      FeedItem.new Nokogiri::XML.fragment(str)
    end

    def list
      @list ||= @store.read(@name) || []
    end

    def save
      @store.write(@name, list)
    end
  end

  def push_new_items_into_queue
    new_items.each do |item|
      new_items_queue.push item
    end
  end

  def new_items
    items.reverse.reject do |it|
      published_items_list.include?(it) || new_items_queue.include?(it)
    end
  end

  def new_items_queue
    @new_items_queue ||= ItemsList.new store, :queue
  end

  def published_items_list
    @published_items_list ||= ItemsList.new store, :published
  end

  def next_item
    return unless need_more_items?
    @next_item ||= new_items_queue.pop
  end

  def need_more_items?
    last_published_at.blank? || (last_published_at <= interval.ago)
  end

  def last_published_at
    store.read(:last_published_at)
  end

  def update_stats!
    store.write(:last_published_at, Time.now)
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
    published_items_list.push next_item if next_item.present?
  end

  def feed_title
    feed_doc.css('title').text
  end
end
