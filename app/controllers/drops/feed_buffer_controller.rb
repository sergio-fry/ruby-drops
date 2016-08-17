class Drops::FeedBufferController < ApplicationController
  def index
    new_items.each do |item|
      new_items_queue.push item
    end

    published_items_list.push next_item if next_item.present?

    render plain: <<-FEED
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
  <title>Сергей Удалов / diggs</title>
  <description></description>

    #{published_items_list.all.join}
</channel>
    FEED

    published!
  end

  private

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

  class ItemsList
    def initialize(store, name)
      @store = store
      @name = name
    end

    def push(item)
      list.push item.to_s
      save
    end

    def pop
      res = FeedItem.new Nokogiri::XML(list.shift)
      save

      res
    end

    def last
      list.last
    end

    def all
      list
    end

    private

    def list
      @list ||= @store.read(@name) || []
    end

    def save
      @store.write(@name, list)
    end
  end

  def new_items
    items
  end

  def new_items_queue
    @new_items_queue ||= ItemsList.new store, :queue
  end

  def published_items_list
    @published_items_list ||= ItemsList.new store, :published
  end

  def next_item
    new_items_queue.pop
  end

  def need_more_items?
    last_published_at <= interval.ago
  end

  def last_published_at
    store.read(:last_published_at)
  end

  def published!
    store.write(:last_published_at, Time.now)
  end

  def items
    feed_doc.css('item').map { |item| FeedItem.new(item) }
  end

  def feed_doc
    Nokogiri::XML(feed_body)
  end

  def feed_body
    open(params[:feed_url]).read
  end

  def store
    @store ||= DropStorage.find_or_create_by(name: :feed_buffer)
  end

  def interval
    params[:interval].to_i.minutes
  end
end
