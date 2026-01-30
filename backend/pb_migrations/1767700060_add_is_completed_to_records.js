/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_records_001");
  
  // is_completed (bool) - 할 일 완료 여부
  collection.fields.addAt(6, new Field({
    "hidden": false,
    "id": "bool_is_completed",
    "name": "is_completed",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "bool"
  }));

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_records_001");
  collection.fields.removeById("bool_is_completed");
  return app.save(collection);
});
