/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_records_001");

  // record_type select - 기록 타입 (할 일/기록/일기)
  collection.fields.addAt(8, new Field({
    "hidden": false,
    "id": "select_record_type",
    "maxSelect": 1,
    "name": "record_type",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "todo",
      "activity",
      "diary"
    ]
  }));

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_records_001");
  collection.fields.removeById("select_record_type");
  return app.save(collection);
});
