class Drops::FeedBufferController < ApplicationController
  def index
    feed = open(params[:feed_url]).read
    render plain: feed
  end
end
