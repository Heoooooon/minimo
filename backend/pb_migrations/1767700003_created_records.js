/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "id": "pbc_records_001",
    "created": "2025-01-06 00:00:00.000Z",
    "updated": "2025-01-06 00:00:00.000Z",
    "name": "records",
    "type": "base",
    "system": false,
    "schema": [],
    "indexes": [],
    "listRule": "",
    "viewRule": "",
    "createRule": "",
    "updateRule": "",
    "deleteRule": "",
    "options": {}
  });

  // aquarium relation (optional)
  collection.fields.addAt(1, new Field({
    "hidden": false,
    "id": "relation_aquarium",
    "name": "aquarium",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation",
    "cascadeDelete": false,
    "collectionId": "pbc_1516323165",
    "maxSelect": 1,
    "minSelect": 0
  }));

  // date
  collection.fields.addAt(2, new Field({
    "hidden": false,
    "id": "date_record",
    "max": "",
    "min": "",
    "name": "date",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "date"
  }));

  // tags (multi-select)
  collection.fields.addAt(3, new Field({
    "hidden": false,
    "id": "select_tags",
    "maxSelect": 7,
    "name": "tags",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "select",
    "values": [
      "water_change",
      "cleaning",
      "feeding",
      "water_test",
      "fish_added",
      "medication",
      "maintenance"
    ]
  }));

  // content
  collection.fields.addAt(4, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text_content",
    "max": 1000,
    "min": 0,
    "name": "content",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }));

  // is_public
  collection.fields.addAt(5, new Field({
    "hidden": false,
    "id": "bool_is_public",
    "name": "is_public",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "bool"
  }));

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_records_001");
  return app.delete(collection);
});
