/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_records_001");

  // creature relation (optional) - 생물별 기록 연결
  collection.fields.addAt(7, new Field({
    "hidden": false,
    "id": "relation_creature",
    "name": "creature",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation",
    "cascadeDelete": false,
    "collectionId": "pbc_creatures",
    "maxSelect": 1,
    "minSelect": 0
  }));

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_records_001");
  collection.fields.removeById("relation_creature");
  return app.save(collection);
});
