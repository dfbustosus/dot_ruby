class Item < Sequel::Model
  plugin :validation_helpers
  plugin :timestamps, update_on_create: true

  def validate
    super
    validates_presence [:name]
    validates_max_length 255, :name
  end

  def to_json(options = {})
    {
      id: id,
      name: name,
      description: description,
      created_at: created_at,
      updated_at: updated_at
    }.to_json(options)
  end
end
