/// <reference path="../pb_data/types.d.ts" />

/**
 * Migration: Add owner field to user-owned collections
 * 
 * Collections affected:
 * - aquariums, records, schedules, creatures, gallery_photos, questions, community_posts
 * 
 * Rules:
 * - Private collections (aquariums, records, schedules, creatures, gallery_photos): owner-only access
 * - Public collections (questions, community_posts): public read, owner-only write
 */
migrate((app) => {
  const collectionsToUpdate = [
    { nameOrId: "pbc_1516323165", name: "aquariums" },
    { nameOrId: "pbc_records_001", name: "records" },
    { nameOrId: "pbc_schedules_001", name: "schedules" },
    { nameOrId: "pbc_creatures_001", name: "creatures" },
    { nameOrId: "pbc_gallery_photos_001", name: "gallery_photos" },
    { nameOrId: "pbc_questions_001", name: "questions" },
    { nameOrId: "pbc_community_posts_001", name: "community_posts" },
  ];

  for (const collectionInfo of collectionsToUpdate) {
    try {
      const collection = app.findCollectionByNameOrId(collectionInfo.nameOrId);
      
      const existingOwnerField = collection.fields.find(f => f.name === "owner");
      if (existingOwnerField) {
        console.log(`Skipping ${collectionInfo.name}: owner field already exists`);
        continue;
      }

      collection.fields.addAt(1, new Field({
        "cascadeDelete": false,
        "collectionId": "_pb_users_auth_",
        "hidden": false,
        "id": `relation_owner_${collectionInfo.name}`,
        "maxSelect": 1,
        "minSelect": 1,
        "name": "owner",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "relation"
      }));

      if (collectionInfo.name === "questions" || collectionInfo.name === "community_posts") {
        collection.listRule = "";
        collection.viewRule = "";
        collection.createRule = "@request.auth.id != ''";
        collection.updateRule = "@request.auth.id = owner";
        collection.deleteRule = "@request.auth.id = owner";
      } else {
        collection.listRule = "@request.auth.id = owner";
        collection.viewRule = "@request.auth.id = owner";
        collection.createRule = "@request.auth.id != ''";
        collection.updateRule = "@request.auth.id = owner";
        collection.deleteRule = "@request.auth.id = owner";
      }

      app.save(collection);
      console.log(`Updated ${collectionInfo.name} with owner field and rules`);
    } catch (e) {
      console.error(`Failed to update ${collectionInfo.name}: ${e.message}`);
    }
  }
}, (app) => {
  const collectionsToUpdate = [
    { nameOrId: "pbc_1516323165", name: "aquariums" },
    { nameOrId: "pbc_records_001", name: "records" },
    { nameOrId: "pbc_schedules_001", name: "schedules" },
    { nameOrId: "pbc_creatures_001", name: "creatures" },
    { nameOrId: "pbc_gallery_photos_001", name: "gallery_photos" },
    { nameOrId: "pbc_questions_001", name: "questions" },
    { nameOrId: "pbc_community_posts_001", name: "community_posts" },
  ];

  for (const collectionInfo of collectionsToUpdate) {
    try {
      const collection = app.findCollectionByNameOrId(collectionInfo.nameOrId);
      
      const ownerField = collection.fields.find(f => f.name === "owner");
      if (ownerField) {
        collection.fields.removeById(ownerField.id);
      }

      collection.listRule = "";
      collection.viewRule = "";
      collection.createRule = "";
      collection.updateRule = "";
      collection.deleteRule = "";

      app.save(collection);
      console.log(`Rolled back ${collectionInfo.name}`);
    } catch (e) {
      console.error(`Failed to rollback ${collectionInfo.name}: ${e.message}`);
    }
  }
});
