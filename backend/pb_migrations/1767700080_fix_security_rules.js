/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collectionsToFix = [
    "pbc_comments_001",
    "pbc_answers_001",
    "pbc_follows_001",
    "pbc_tags_001",
  ];

  for (const id of collectionsToFix) {
    try {
      const collection = app.findCollectionByNameOrId(id);

      collection.listRule = "";
      collection.viewRule = "";
      collection.createRule = "@request.auth.id != ''";
      collection.updateRule = "@request.auth.id = author";
      collection.deleteRule = "@request.auth.id = author";

      if (id === "pbc_follows_001") {
        collection.updateRule = "@request.auth.id = follower";
        collection.deleteRule = "@request.auth.id = follower";
      }

      if (id === "pbc_tags_001") {
        collection.createRule = "@request.auth.id != ''";
        collection.updateRule = "";
        collection.deleteRule = "";
      }

      app.save(collection);
      console.log("Fixed security rules for: " + id);
    } catch (e) {
      console.error("Failed to fix rules for " + id + ": " + e.message);
    }
  }
}, (app) => {
  const collectionsToReset = [
    "pbc_comments_001",
    "pbc_answers_001",
    "pbc_follows_001",
    "pbc_tags_001",
  ];

  for (const id of collectionsToReset) {
    try {
      const collection = app.findCollectionByNameOrId(id);
      collection.listRule = "";
      collection.viewRule = "";
      collection.createRule = "";
      collection.updateRule = "";
      collection.deleteRule = "";
      app.save(collection);
    } catch (e) {
      console.error("Failed to reset rules for " + id + ": " + e.message);
    }
  }
});
