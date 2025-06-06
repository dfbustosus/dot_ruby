Sequel.migration do
  up do
    create_table(:items) do
      primary_key :id
      String :name, null: false
      String :description, text: true
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      
      index :name
    end
  end

  down do
    drop_table(:items)
  end
end
