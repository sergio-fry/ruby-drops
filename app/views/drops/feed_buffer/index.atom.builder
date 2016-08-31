atom_feed do |feed|
  feed.title("My great blog!")
  feed.updated(@items[0].published) if @items.present?

  @items.each do |item|
    feed.entry(item, id: item.url, url: item.url) do |entry|
      entry.title(item.title)
      entry.content(item.content, type: 'html')

      entry.author do |author|
        author.name("Udalov")
      end
    end
  end
end
