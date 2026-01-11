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
        "cascadeDelete": false,
        "collectionId": "pbc_creatures",
        "hidden": false,
        "id": "relation_creature",
        "maxSelect": 1,
        "minSelect": 0,
        "name": "creature_id",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "relation"
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
        "required": true,
        "system": false,
        "thumbs": [
          "100x100",
          "300x300",
          "600x600"
        ],
        "type": "file"
      },
      {
        "hidden": false,
        "id": "date_photo",
        "max": "",
        "min": "",
        "name": "photo_date",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "date"
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text_caption",
        "max": 200,
        "min": 0,
        "name": "caption",
        "pattern": "",
        "presentable": false,
        "primaryKey": false,
        "required": false,
        "system": false,
        "type": "text"
      }
    ],
    "id": "pbc_gallery_photos",
    "indexes": [
      "CREATE INDEX idx_gallery_aquarium ON gallery_photos (aquarium_id)",
      "CREATE INDEX idx_gallery_creature ON gallery_photos (creature_id)",
      "CREATE INDEX idx_gallery_date ON gallery_photos (photo_date DESC)"
    ],
    "listRule": "",
    "name": "gallery_photos",
    "system": false,
    "type": "base",
    "updateRule": "",
    "viewRule": ""
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_gallery_photos");

  return app.delete(collection);
})
