class DropStorage < ApplicationRecord
  serialize :store, Hash
  validates :name, presence: true, uniqueness: true

  def write(key, value)
    store[key.to_s] = value
    save
  end

  def read(key)
    store[key.to_s]
  end
end
