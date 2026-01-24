/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("_pb_users_auth_");

  collection.fields.addAt(collection.fields.length, new Field({
    "hidden": false,
    "id": "text_fcm_token",
    "name": "fcm_token",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "text",
    "max": 500,
    "min": 0,
    "pattern": ""
  }));

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("_pb_users_auth_");

  const field = collection.fields.find(f => f.name === "fcm_token");
  if (field) {
    collection.fields.removeById(field.id);
  }

  return app.save(collection);
});
