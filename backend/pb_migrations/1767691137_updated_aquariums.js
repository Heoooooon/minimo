/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1516323165")

  // add field
  collection.fields.addAt(1, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text1579384326",
    "max": 50,
    "min": 0,
    "name": "name",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(2, new Field({
    "hidden": false,
    "id": "select2363381545",
    "maxSelect": 1,
    "name": "type",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "select",
    "values": [
      "freshwater",
      "saltwater"
    ]
  }))

  // add field
  collection.fields.addAt(3, new Field({
    "hidden": false,
    "id": "date1797921692",
    "max": "",
    "min": "",
    "name": "setting_date",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "date"
  }))

  // add field
  collection.fields.addAt(4, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text3799878565",
    "max": 100,
    "min": 0,
    "name": "dimensions",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(5, new Field({
    "hidden": false,
    "id": "select3840159824",
    "maxSelect": 1,
    "name": "filter_type",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "hang_on",
      "canister",
      "sponge",
      "internal",
      "sump",
      "none"
    ]
  }))

  // add field
  collection.fields.addAt(6, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text2834493635",
    "max": 100,
    "min": 0,
    "name": "substrate",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(7, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text3553320103",
    "max": 100,
    "min": 0,
    "name": "product_name",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(8, new Field({
    "hidden": false,
    "id": "select3406304627",
    "maxSelect": 1,
    "name": "lighting",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "led",
      "fluorescent",
      "metal_halide",
      "none"
    ]
  }))

  // add field
  collection.fields.addAt(9, new Field({
    "hidden": false,
    "id": "bool1918110641",
    "name": "heater",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "bool"
  }))

  // add field
  collection.fields.addAt(10, new Field({
    "hidden": false,
    "id": "select3095901163",
    "maxSelect": 1,
    "name": "purpose",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "general",
      "breeding",
      "aquascape",
      "neglect",
      "fry"
    ]
  }))

  // add field
  collection.fields.addAt(11, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text18589324",
    "max": 300,
    "min": 0,
    "name": "notes",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(12, new Field({
    "hidden": false,
    "id": "file347571224",
    "maxSelect": 1,
    "maxSize": 5242880,
    "mimeTypes": [
      "image/jpeg",
      "image/png",
      "image/webp"
    ],
    "name": "photo",
    "presentable": false,
    "protected": false,
    "required": false,
    "system": false,
    "thumbs": null,
    "type": "file"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1516323165")

  // remove field
  collection.fields.removeById("text1579384326")

  // remove field
  collection.fields.removeById("select2363381545")

  // remove field
  collection.fields.removeById("date1797921692")

  // remove field
  collection.fields.removeById("text3799878565")

  // remove field
  collection.fields.removeById("select3840159824")

  // remove field
  collection.fields.removeById("text2834493635")

  // remove field
  collection.fields.removeById("text3553320103")

  // remove field
  collection.fields.removeById("select3406304627")

  // remove field
  collection.fields.removeById("bool1918110641")

  // remove field
  collection.fields.removeById("select3095901163")

  // remove field
  collection.fields.removeById("text18589324")

  // remove field
  collection.fields.removeById("file347571224")

  return app.save(collection)
})
