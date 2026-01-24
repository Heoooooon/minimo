/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "id": "pbc_notifications_001",
    "created": "2025-01-24 00:00:00.000Z",
    "updated": "2025-01-24 00:00:00.000Z",
    "name": "notifications",
    "type": "base",
    "system": false,
    "schema": [],
    "indexes": [
      "CREATE INDEX idx_notifications_user ON notifications (user)",
      "CREATE INDEX idx_notifications_is_read ON notifications (is_read)"
    ],
    "listRule": "@request.auth.id = user",
    "viewRule": "@request.auth.id = user",
    "createRule": "",
    "updateRule": "@request.auth.id = user",
    "deleteRule": "@request.auth.id = user",
    "options": {}
  });

  collection.fields.addAt(1, new Field({
    "hidden": false,
    "id": "relation_user",
    "name": "user",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "relation",
    "cascadeDelete": true,
    "collectionId": "_pb_users_auth_",
    "maxSelect": 1,
    "minSelect": 1
  }));

  collection.fields.addAt(2, new Field({
    "hidden": false,
    "id": "select_type",
    "name": "type",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "select",
    "maxSelect": 1,
    "values": ["like", "comment", "follow", "answer", "mention", "system"]
  }));

  collection.fields.addAt(3, new Field({
    "hidden": false,
    "id": "text_title",
    "name": "title",
    "presentable": true,
    "required": true,
    "system": false,
    "type": "text",
    "max": 200,
    "min": 1,
    "pattern": ""
  }));

  collection.fields.addAt(4, new Field({
    "hidden": false,
    "id": "text_message",
    "name": "message",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "text",
    "max": 500,
    "min": 1,
    "pattern": ""
  }));

  collection.fields.addAt(5, new Field({
    "hidden": false,
    "id": "text_target_id",
    "name": "target_id",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "text",
    "max": 50,
    "min": 0,
    "pattern": ""
  }));

  collection.fields.addAt(6, new Field({
    "hidden": false,
    "id": "select_target_type",
    "name": "target_type",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "maxSelect": 1,
    "values": ["post", "question", "user", "comment", "answer"]
  }));

  collection.fields.addAt(7, new Field({
    "hidden": false,
    "id": "bool_is_read",
    "name": "is_read",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "bool"
  }));

  collection.fields.addAt(8, new Field({
    "hidden": false,
    "id": "relation_actor",
    "name": "actor",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation",
    "cascadeDelete": false,
    "collectionId": "_pb_users_auth_",
    "maxSelect": 1,
    "minSelect": 0
  }));

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_notifications_001");
  return app.delete(collection);
});
