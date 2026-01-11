/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "id": "pbc_community_posts_001",
    "created": "2025-01-06 00:00:00.000Z",
    "updated": "2025-01-06 00:00:00.000Z",
    "name": "community_posts",
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

  // author_name
  collection.fields.addAt(1, new Field({
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

  // author_image (optional file)
  collection.fields.addAt(2, new Field({
    "hidden": false,
    "id": "file_author_image",
    "maxSelect": 1,
    "maxSize": 2097152,
    "mimeTypes": [
      "image/jpeg",
      "image/png",
      "image/webp"
    ],
    "name": "author_image",
    "presentable": false,
    "protected": false,
    "required": false,
    "system": false,
    "thumbs": ["100x100"],
    "type": "file"
  }));

  // content
  collection.fields.addAt(3, new Field({
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

  // image (optional file)
  collection.fields.addAt(4, new Field({
    "hidden": false,
    "id": "file_image",
    "maxSelect": 1,
    "maxSize": 5242880,
    "mimeTypes": [
      "image/jpeg",
      "image/png",
      "image/webp"
    ],
    "name": "image",
    "presentable": false,
    "protected": false,
    "required": false,
    "system": false,
    "thumbs": ["400x300"],
    "type": "file"
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

  // bookmark_count
  collection.fields.addAt(7, new Field({
    "hidden": false,
    "id": "number_bookmark_count",
    "max": null,
    "min": 0,
    "name": "bookmark_count",
    "onlyInt": true,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }));

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_community_posts_001");
  return app.delete(collection);
});
