/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "id": "pbc_follows_001",
    "created": "2025-01-06 00:00:00.000Z",
    "updated": "2025-01-06 00:00:00.000Z",
    "name": "follows",
    "type": "base",
    "system": false,
    "schema": [],
    "indexes": [
      "CREATE UNIQUE INDEX idx_follows_unique ON follows (follower, following)"
    ],
    "listRule": "",
    "viewRule": "",
    "createRule": "",
    "updateRule": "",
    "deleteRule": "",
    "options": {}
  });

  // follower (relation to users collection)
  collection.fields.addAt(1, new Field({
    "hidden": false,
    "id": "relation_follower",
    "name": "follower",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "relation",
    "cascadeDelete": true,
    "collectionId": "_pb_users_auth_",
    "maxSelect": 1,
    "minSelect": 1
  }));

  // following (relation to users collection)
  collection.fields.addAt(2, new Field({
    "hidden": false,
    "id": "relation_following",
    "name": "following",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "relation",
    "cascadeDelete": true,
    "collectionId": "_pb_users_auth_",
    "maxSelect": 1,
    "minSelect": 1
  }));

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_follows_001");
  return app.delete(collection);
});
