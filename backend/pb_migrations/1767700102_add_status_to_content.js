/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // community_posts에 status 필드 추가
  const posts = app.findCollectionByNameOrId("community_posts");
  posts.fields.addAt(posts.fields.length, new Field({
    "hidden": false,
    "id": "select_status",
    "name": "status",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "maxSelect": 1,
    "values": ["active", "hidden", "deleted"]
  }));
  app.save(posts);

  // questions에 status 필드 추가
  const questions = app.findCollectionByNameOrId("questions");
  questions.fields.addAt(questions.fields.length, new Field({
    "hidden": false,
    "id": "select_q_status",
    "name": "status",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "maxSelect": 1,
    "values": ["active", "hidden", "deleted"]
  }));
  app.save(questions);
}, (app) => {
  const posts = app.findCollectionByNameOrId("community_posts");
  posts.fields.removeById("select_status");
  app.save(posts);

  const questions = app.findCollectionByNameOrId("questions");
  questions.fields.removeById("select_q_status");
  app.save(questions);
});
