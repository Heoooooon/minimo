/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_questions_001");

  const categoryField = collection.fields.find(f => f.name === "category");
  if (categoryField) {
    categoryField.values = [
      "수질",
      "질병",
      "먹이",
      "장비",
      "어종",
      "수초",
      "기타"
    ];
  }

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_questions_001");

  const categoryField = collection.fields.find(f => f.name === "category");
  if (categoryField) {
    categoryField.values = [
      "beginner",
      "maintenance",
      "species",
      "disease",
      "equipment",
      "other"
    ];
  }

  return app.save(collection);
});
