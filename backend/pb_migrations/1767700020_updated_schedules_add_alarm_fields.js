/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_schedules_001");

  // alarm_type (select: water_change, feeding, cleaning, water_test, medication, other)
  collection.fields.addAt(7, new Field({
    "hidden": false,
    "id": "select_alarm_type",
    "name": "alarm_type",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": ["water_change", "feeding", "cleaning", "water_test", "medication", "other"],
    "maxSelect": 1
  }));

  // repeat_cycle (select: daily, every_other_day, weekly, biweekly, monthly, none)
  collection.fields.addAt(8, new Field({
    "hidden": false,
    "id": "select_repeat_cycle",
    "name": "repeat_cycle",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": ["daily", "every_other_day", "weekly", "biweekly", "monthly", "none"],
    "maxSelect": 1
  }));

  // is_notification_enabled (push notification toggle)
  collection.fields.addAt(9, new Field({
    "hidden": false,
    "id": "bool_notification_enabled",
    "name": "is_notification_enabled",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "bool"
  }));

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_schedules_001");

  collection.fields.removeById("select_alarm_type");
  collection.fields.removeById("select_repeat_cycle");
  collection.fields.removeById("bool_notification_enabled");

  return app.save(collection);
});
