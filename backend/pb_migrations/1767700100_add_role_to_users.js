/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("users");

  // role select 필드 추가 (user, admin)
  collection.fields.addAt(collection.fields.length, new Field({
    "hidden": false,
    "id": "select_role",
    "name": "role",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "maxSelect": 1,
    "values": ["user", "admin"]
  }));

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("users");
  collection.fields.removeById("select_role");
  return app.save(collection);
});
