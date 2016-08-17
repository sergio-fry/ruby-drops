Rails.application.routes.draw do
  namespace :drops do
    get 'feed_buffer', controller: 'feed_buffer', action: :index
  end
end
