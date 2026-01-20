/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_comments_001");

  // parent_comment (for nested replies, optional)
  collection.fields.addAt(6, new Field({
    "hidden": false,
    "id": "relation_parent_comment",
    "name": "parent_comment",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation",
    "cascadeDelete": true,
    "collectionId": "pbc_comments_001",
    "maxSelect": 1,
    "minSelect": 0
  }));

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_comments_001");

  // Remove the parent_comment field
  const field = collection.fields.find(f => f.name === "parent_comment");
  if (field) {
    collection.fields.removeById(field.id);
  }

  return app.save(collection);
});
