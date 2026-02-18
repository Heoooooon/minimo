/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_records_001");

  // tags 필드를 optional로 변경 (일기는 태그 불필요)
  const tagsField = collection.fields.find(f => f.name === "tags");
  if (tagsField) {
    tagsField.required = false;
  }

  // content 필드를 optional로 변경 (할 일은 content 불필요할 수 있음)
  const contentField = collection.fields.find(f => f.name === "content");
  if (contentField) {
    contentField.required = false;
  }

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_records_001");

  // 원복: tags, content를 required로
  const tagsField = collection.fields.find(f => f.name === "tags");
  if (tagsField) {
    tagsField.required = true;
  }

  const contentField = collection.fields.find(f => f.name === "content");
  if (contentField) {
    contentField.required = true;
  }

  return app.save(collection);
});
