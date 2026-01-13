migrate((app) => {
  const collection = new Collection({
    "id": "pbc_creature_catalog",
    "name": "creature_catalog",
    "type": "base",
    "system": false,
    "listRule": "status = 'public' && report_count < 5",
    "viewRule": "status = 'public' && report_count < 5",
    "createRule": "@request.auth.id != '' && created_by = @request.auth.id && status = 'public' && report_count = 0 && name !~ '씨발' && name !~ '병신' && name !~ '좆' && name !~ 'fuck' && category !~ '씨발' && category !~ '병신' && category !~ '좆' && category !~ 'fuck'",
    "updateRule": "@request.auth.id != '' && created_by = @request.auth.id",
    "deleteRule": "@request.auth.id != '' && created_by = @request.auth.id",
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
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text_category",
        "max": 50,
        "min": 1,
        "name": "category",
        "pattern": "",
        "presentable": true,
        "primaryKey": false,
        "required": true,
        "system": false,
        "type": "text"
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text_name",
        "max": 100,
        "min": 1,
        "name": "name",
        "pattern": "",
        "presentable": true,
        "primaryKey": false,
        "required": true,
        "system": false,
        "type": "text"
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text_normalized_key",
        "max": 200,
        "min": 1,
        "name": "normalized_key",
        "pattern": "",
        "presentable": false,
        "primaryKey": false,
        "required": true,
        "system": false,
        "type": "text"
      },
      {
        "hidden": false,
        "id": "file_image",
        "maxSelect": 1,
        "maxSize": 10485760,
        "mimeTypes": [
          "image/jpeg",
          "image/png",
          "image/webp",
          "image/gif"
        ],
        "name": "image",
        "presentable": false,
        "protected": false,
        "required": false,
        "system": false,
        "thumbs": [
          "100x100",
          "300x300",
          "600x600"
        ],
        "type": "file"
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text_created_by",
        "max": 15,
        "min": 15,
        "name": "created_by",
        "pattern": "^[a-z0-9]+$",
        "presentable": false,
        "primaryKey": false,
        "required": true,
        "system": false,
        "type": "text"
      },
      {
        "hidden": false,
        "id": "select_status",
        "maxSelect": 1,
        "name": "status",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "select",
        "values": [
          "public",
          "hidden"
        ]
      },
      {
        "hidden": false,
        "id": "number_report_count",
        "max": null,
        "min": 0,
        "name": "report_count",
        "onlyInt": true,
        "presentable": false,
        "required": true,
        "system": false,
        "type": "number"
      }
    ],
    "indexes": [
      "CREATE UNIQUE INDEX idx_creature_catalog_normalized_key ON creature_catalog (normalized_key)",
      "CREATE INDEX idx_creature_catalog_category ON creature_catalog (category)",
      "CREATE INDEX idx_creature_catalog_name ON creature_catalog (name)"
    ]
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_creature_catalog");

  return app.delete(collection);
});
