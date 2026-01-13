migrate((app) => {
  const collection = new Collection({
    "id": "pbc_creature_catalog_reports",
    "name": "creature_catalog_reports",
    "type": "base",
    "system": false,
    "listRule": "@request.auth.id != '' && reporter_id = @request.auth.id",
    "viewRule": "@request.auth.id != '' && reporter_id = @request.auth.id",
    "createRule": "@request.auth.id != '' && reporter_id = @request.auth.id",
    "updateRule": "",
    "deleteRule": "@request.auth.id != '' && reporter_id = @request.auth.id",
    "fields": [
      {
        "autogeneratePattern": "[a-z0-9]{15}",
        "hidden": false,
        "id": "text3208210256",
        "max": 15,
        "min": 15,
        "name": "id",
        "pattern": "^[a-z0-9]+$",
        "presentable": false,
        "primaryKey": true,
        "required": true,
        "system": true,
        "type": "text"
      },
      {
        "cascadeDelete": true,
        "collectionId": "pbc_creature_catalog",
        "hidden": false,
        "id": "relation_catalog",
        "maxSelect": 1,
        "minSelect": 1,
        "name": "catalog_id",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "relation"
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text_reporter_id",
        "max": 15,
        "min": 15,
        "name": "reporter_id",
        "pattern": "^[a-z0-9]+$",
        "presentable": false,
        "primaryKey": false,
        "required": true,
        "system": false,
        "type": "text"
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text_reason",
        "max": 200,
        "min": 0,
        "name": "reason",
        "pattern": "",
        "presentable": false,
        "primaryKey": false,
        "required": false,
        "system": false,
        "type": "text"
      }
    ],
    "indexes": [
      "CREATE UNIQUE INDEX idx_creature_catalog_reports_unique ON creature_catalog_reports (catalog_id, reporter_id)",
      "CREATE INDEX idx_creature_catalog_reports_catalog ON creature_catalog_reports (catalog_id)"
    ]
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_creature_catalog_reports");

  return app.delete(collection);
});
