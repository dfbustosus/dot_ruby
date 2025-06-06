require_relative '../models/item'

class ItemsController
  class << self
    def index
      items = Item.all
      [200, items.map(&:to_hash)]
    end

    def show(id)
      item = Item[id]
      return [404, { error: 'Item not found' }] unless item
      
      [200, item.to_hash]
    end

    def create(params)
      begin
        item = Item.new(
          name: params['name'],
          description: params['description']
        )
        
        if item.valid? && item.save
          [201, item.to_hash]
        else
          [422, { error: item.errors.full_messages }]
        end
      rescue Sequel::Error => e
        [500, { error: e.message }]
      end
    end

    def update(id, params)
      item = Item[id]
      return [404, { error: 'Item not found' }] unless item
      
      begin
        # Only update fields that are provided
        item.name = params['name'] if params['name']
        item.description = params['description'] if params['description']
        
        if item.valid? && item.save
          [200, item.to_hash]
        else
          [422, { error: item.errors.full_messages }]
        end
      rescue Sequel::Error => e
        [500, { error: e.message }]
      end
    end

    def delete(id)
      item = Item[id]
      return [404, { error: 'Item not found' }] unless item
      
      begin
        item.delete
        [204, nil]
      rescue Sequel::Error => e
        [500, { error: e.message }]
      end
    end
  end
end
