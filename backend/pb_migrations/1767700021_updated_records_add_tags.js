/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_records_001");

  // Update tags field to include temperature_check and plant_care
  const tagsField = collection.fields.find(f => f.name === "tags");
  if (tagsField) {
    tagsField.values = [
      "water_change",
      "cleaning",
      "feeding",
      "water_test",
      "fish_added",
      "medication",
      "maintenance",
      "temperature_check",
      "plant_care"
    ];
    tagsField.maxSelect = 9;
  }

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_records_001");

  // Revert to original tags
  const tagsField = collection.fields.find(f => f.name === "tags");
  if (tagsField) {
    tagsField.values = [
      "water_change",
      "cleaning",
      "feeding",
      "water_test",
      "fish_added",
      "medication",
      "maintenance"
    ];
    tagsField.maxSelect = 7;
  }

  return app.save(collection);
});
