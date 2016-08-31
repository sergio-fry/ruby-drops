atom_feed do |feed|
  feed.title @feed_title
  feed.updated(@items[0].published) if @items.present?

  @items.each do |item|
    feed.entry(item, id: item.url, url: item.url, updated: item.published) do |entry|
      entry.title(item.title)
      entry.content( simple_format(item.content || item.summary), type: 'html')

      entry.author do |author|
        author.name item.author || @author
      end
    end
  end
end
