/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "id": "pbc_schedules_001",
    "created": "2025-01-06 00:00:00.000Z",
    "updated": "2025-01-06 00:00:00.000Z",
    "name": "schedules",
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
    "id": "date_schedule",
    "max": "",
    "min": "",
    "name": "date",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "date"
  }));

  // time (HH:mm format)
  collection.fields.addAt(3, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text_time",
    "max": 5,
    "min": 5,
    "name": "time",
    "pattern": "^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }));

  // title
  collection.fields.addAt(4, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text_title",
    "max": 100,
    "min": 1,
    "name": "title",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }));

  // aquarium_name (denormalized for display)
  collection.fields.addAt(5, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text_aquarium_name",
    "max": 50,
    "min": 0,
    "name": "aquarium_name",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }));

  // is_completed
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
  const collection = app.findCollectionByNameOrId("pbc_schedules_001");
  return app.delete(collection);
});
