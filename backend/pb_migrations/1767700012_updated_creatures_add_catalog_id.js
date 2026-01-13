migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_creatures");

  collection.fields.addAt(2, new Field({
    "cascadeDelete": false,
    "collectionId": "pbc_creature_catalog",
    "hidden": false,
    "id": "relation_catalog_id",
    "maxSelect": 1,
    "minSelect": 0,
    "name": "catalog_id",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation"
  }));

  collection.indexes = (collection.indexes || []).concat([
    "CREATE INDEX idx_creatures_catalog_id ON creatures (catalog_id)"
  ]);

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_creatures");

  collection.fields.removeById("relation_catalog_id");
  collection.indexes = (collection.indexes || []).filter((idx) => idx !== "CREATE INDEX idx_creatures_catalog_id ON creatures (catalog_id)");

  return app.save(collection);
});
