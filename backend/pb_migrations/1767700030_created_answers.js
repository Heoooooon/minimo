/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "id": "pbc_answers_001",
    "created": "2025-01-06 00:00:00.000Z",
    "updated": "2025-01-06 00:00:00.000Z",
    "name": "answers",
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

  // question (relation to questions collection)
  collection.fields.addAt(1, new Field({
    "hidden": false,
    "id": "relation_question",
    "name": "question",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "relation",
    "cascadeDelete": true,
    "collectionId": "pbc_questions_001",
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

  // is_accepted
  collection.fields.addAt(5, new Field({
    "hidden": false,
    "id": "bool_is_accepted",
    "name": "is_accepted",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "bool"
  }));

  // like_count
  collection.fields.addAt(6, new Field({
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
  const collection = app.findCollectionByNameOrId("pbc_answers_001");
  return app.delete(collection);
});
