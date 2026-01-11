/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "id": "pbc_questions_001",
    "created": "2025-01-06 00:00:00.000Z",
    "updated": "2025-01-06 00:00:00.000Z",
    "name": "questions",
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

  // title
  collection.fields.addAt(1, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text_title",
    "max": 200,
    "min": 1,
    "name": "title",
    "pattern": "",
    "presentable": true,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }));

  // content
  collection.fields.addAt(2, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text_content",
    "max": 5000,
    "min": 1,
    "name": "content",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }));

  // category
  collection.fields.addAt(3, new Field({
    "hidden": false,
    "id": "select_category",
    "maxSelect": 1,
    "name": "category",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "select",
    "values": [
      "beginner",
      "maintenance",
      "species",
      "disease",
      "equipment",
      "other"
    ]
  }));

  // attached_records (relation to records collection)
  collection.fields.addAt(4, new Field({
    "hidden": false,
    "id": "relation_attached_records",
    "name": "attached_records",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation",
    "cascadeDelete": false,
    "collectionId": "pbc_records_001",
    "maxSelect": 10,
    "minSelect": 0
  }));

  // view_count
  collection.fields.addAt(5, new Field({
    "hidden": false,
    "id": "number_view_count",
    "max": null,
    "min": 0,
    "name": "view_count",
    "onlyInt": true,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }));

  // comment_count
  collection.fields.addAt(6, new Field({
    "hidden": false,
    "id": "number_comment_count",
    "max": null,
    "min": 0,
    "name": "comment_count",
    "onlyInt": true,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }));

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_questions_001");
  return app.delete(collection);
});
