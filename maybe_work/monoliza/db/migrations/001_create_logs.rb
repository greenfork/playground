Sequel.migration do
  change do
    create_table :logs do
      primary_key :id
      String :app, null: false
      String :log, null: false
      TrueClass :is_error, null: false, default: false
    end
  end
end
