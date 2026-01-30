/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "id": "pbc_likes_001",
    "created": "2025-01-30 00:00:00.000Z",
    "updated": "2025-01-30 00:00:00.000Z",
    "name": "likes",
    "type": "base",
    "system": false,
    "schema": [],
    "indexes": [
      "CREATE UNIQUE INDEX idx_likes_user_target ON likes (user, target_id, target_type)",
      "CREATE INDEX idx_likes_target ON likes (target_id, target_type)"
    ],
    "listRule": "",
    "viewRule": "",
    "createRule": "@request.auth.id != ''",
    "updateRule": "",
    "deleteRule": "@request.auth.id = user",
    "options": {}
  });

  // user - 좋아요 누른 사람
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

  // target_id - 좋아요 대상 ID
  collection.fields.addAt(2, new Field({
    "hidden": false,
    "id": "text_target_id",
    "name": "target_id",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "text",
    "max": 50,
    "min": 1,
    "pattern": ""
  }));

  // target_type - 좋아요 대상 타입
  collection.fields.addAt(3, new Field({
    "hidden": false,
    "id": "select_target_type",
    "name": "target_type",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "select",
    "maxSelect": 1,
    "values": ["post", "comment", "answer"]
  }));

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_likes_001");
  return app.delete(collection);
});
