/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "name": "reports",
    "type": "base",
    "system": false,
    "listRule": "",
    "viewRule": "",
    "createRule": "@request.auth.id != ''",
    "updateRule": "",
    "deleteRule": "",
    "fields": [
      {
        "id": "relation_reporter",
        "name": "reporter",
        "type": "relation",
        "required": true,
        "collectionId": "_pb_users_auth_",
        "cascadeDelete": false,
        "maxSelect": 1,
        "minSelect": 0
      },
      {
        "id": "text_target_id",
        "name": "target_id",
        "type": "text",
        "required": true
      },
      {
        "id": "select_target_type",
        "name": "target_type",
        "type": "select",
        "required": true,
        "maxSelect": 1,
        "values": ["post", "question", "comment", "answer", "user"]
      },
      {
        "id": "text_reason",
        "name": "reason",
        "type": "text",
        "required": true
      },
      {
        "id": "text_detail",
        "name": "detail",
        "type": "text",
        "required": false
      },
      {
        "id": "select_report_status",
        "name": "status",
        "type": "select",
        "required": false,
        "maxSelect": 1,
        "values": ["pending", "resolved", "dismissed"]
      },
      {
        "id": "relation_resolved_by",
        "name": "resolved_by",
        "type": "relation",
        "required": false,
        "collectionId": "_pb_users_auth_",
        "cascadeDelete": false,
        "maxSelect": 1,
        "minSelect": 0
      },
      {
        "id": "select_action_taken",
        "name": "action_taken",
        "type": "select",
        "required": false,
        "maxSelect": 1,
        "values": ["warning", "delete", "block", "none"]
      },
      {
        "id": "text_admin_note",
        "name": "admin_note",
        "type": "text",
        "required": false
      },
      {
        "id": "autodate_created",
        "name": "created",
        "type": "autodate",
        "onCreate": true,
        "onUpdate": false
      },
      {
        "id": "autodate_updated",
        "name": "updated",
        "type": "autodate",
        "onCreate": true,
        "onUpdate": true
      }
    ]
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("reports");
  return app.delete(collection);
});
