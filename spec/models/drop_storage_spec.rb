require 'rails_helper'

RSpec.describe DropStorage, type: :model do
  it 'should allow to store structures' do
    drop_storage = DropStorage.create name: :store1
    drop_storage.write(:a, [1, 2, 3])
    drop_storage.reload
    expect(drop_storage.read(:a)).to eq [1, 2, 3]
  end
end
