/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "id": "pbc_tags_001",
    "created": "2025-01-06 00:00:00.000Z",
    "updated": "2025-01-06 00:00:00.000Z",
    "name": "tags",
    "type": "base",
    "system": false,
    "schema": [],
    "indexes": [
      "CREATE UNIQUE INDEX idx_tags_name ON tags (name)"
    ],
    "listRule": "",
    "viewRule": "",
    "createRule": "",
    "updateRule": "",
    "deleteRule": "",
    "options": {}
  });

  // name
  collection.fields.addAt(1, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text_name",
    "max": 50,
    "min": 1,
    "name": "name",
    "pattern": "",
    "presentable": true,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }));

  // usage_count
  collection.fields.addAt(2, new Field({
    "hidden": false,
    "id": "number_usage_count",
    "max": null,
    "min": 0,
    "name": "usage_count",
    "onlyInt": true,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }));

  // category (optional categorization)
  collection.fields.addAt(3, new Field({
    "hidden": false,
    "id": "select_category",
    "maxSelect": 1,
    "name": "category",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "species",
      "equipment",
      "maintenance",
      "disease",
      "general"
    ]
  }));

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_tags_001");
  return app.delete(collection);
});
