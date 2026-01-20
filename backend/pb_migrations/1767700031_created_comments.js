/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "id": "pbc_comments_001",
    "created": "2025-01-06 00:00:00.000Z",
    "updated": "2025-01-06 00:00:00.000Z",
    "name": "comments",
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

  // post (relation to community_posts collection)
  collection.fields.addAt(1, new Field({
    "hidden": false,
    "id": "relation_post",
    "name": "post",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "relation",
    "cascadeDelete": true,
    "collectionId": "pbc_community_posts_001",
    "maxSelect": 1,
    "minSelect": 1
  }));

  // author (relation to users collection)
  collection.fields.addAt(2, new Field({
    "hidden": false,
    "id": "relation_author",
    "name": "author",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation",
    "cascadeDelete": false,
    "collectionId": "_pb_users_auth_",
    "maxSelect": 1,
    "minSelect": 0
  }));

  // author_name (for display if user is deleted)
  collection.fields.addAt(3, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text_author_name",
    "max": 50,
    "min": 1,
    "name": "author_name",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }));

  // content
  collection.fields.addAt(4, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text_content",
    "max": 2000,
    "min": 1,
    "name": "content",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }));

  // like_count
  collection.fields.addAt(5, new Field({
    "hidden": false,
    "id": "number_like_count",
    "max": null,
    "min": 0,
    "name": "like_count",
    "onlyInt": true,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }));

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_comments_001");
  return app.delete(collection);
});
