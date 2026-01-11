/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "createRule": "",
    "deleteRule": "",
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
        "collectionId": "pbc_1516323165",
        "hidden": false,
        "id": "relation_aquarium",
        "maxSelect": 1,
        "minSelect": 1,
        "name": "aquarium_id",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "relation"
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text_name",
        "max": 100,
        "min": 0,
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
        "id": "text_type",
        "max": 100,
        "min": 0,
        "name": "type",
        "pattern": "",
        "presentable": false,
        "primaryKey": false,
        "required": true,
        "system": false,
        "type": "text"
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text_nickname",
        "max": 50,
        "min": 0,
        "name": "nickname",
        "pattern": "",
        "presentable": false,
        "primaryKey": false,
        "required": false,
        "system": false,
        "type": "text"
      },
      {
        "hidden": false,
        "id": "date_adoption",
        "max": "",
        "min": "",
        "name": "adoption_date",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "date"
      },
      {
        "hidden": false,
        "id": "bool_unknown_date",
        "name": "unknown_adoption_date",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "bool"
      },
      {
        "hidden": false,
        "id": "number_quantity",
        "max": 9999,
        "min": 1,
        "name": "quantity",
        "onlyInt": true,
        "presentable": false,
        "required": false,
        "system": false,
        "type": "number"
      },
      {
        "hidden": false,
        "id": "select_gender",
        "maxSelect": 1,
        "name": "gender",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "select",
        "values": [
          "male",
          "female",
          "mixed",
          "unknown"
        ]
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text_source",
        "max": 200,
        "min": 0,
        "name": "source",
        "pattern": "",
        "presentable": false,
        "primaryKey": false,
        "required": false,
        "system": false,
        "type": "text"
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text_price",
        "max": 50,
        "min": 0,
        "name": "price",
        "pattern": "",
        "presentable": false,
        "primaryKey": false,
        "required": false,
        "system": false,
        "type": "text"
      },
      {
        "hidden": false,
        "id": "file_photos",
        "maxSelect": 10,
        "maxSize": 10485760,
        "mimeTypes": [
          "image/jpeg",
          "image/png",
          "image/webp",
          "image/gif"
        ],
        "name": "photos",
        "presentable": false,
        "protected": false,
        "required": false,
        "system": false,
        "thumbs": [
          "100x100",
          "300x300"
        ],
        "type": "file"
      }
    ],
    "id": "pbc_creatures",
    "indexes": [
      "CREATE INDEX idx_creatures_aquarium ON creatures (aquarium_id)"
    ],
    "listRule": "",
    "name": "creatures",
    "system": false,
    "type": "base",
    "updateRule": "",
    "viewRule": ""
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_creatures");

  return app.delete(collection);
})
