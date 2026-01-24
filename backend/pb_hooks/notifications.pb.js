/// <reference path="../pb_data/types.d.ts" />

const FCM_SERVER_KEY = $os.getenv("FCM_SERVER_KEY") || "";

function sendFcmPush(fcmToken, title, body, data) {
    if (!FCM_SERVER_KEY || !fcmToken) {
        return;
    }

    try {
        const response = $http.send({
            url: "https://fcm.googleapis.com/fcm/send",
            method: "POST",
            headers: {
                "Authorization": "key=" + FCM_SERVER_KEY,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                to: fcmToken,
                notification: {
                    title: title,
                    body: body,
                    sound: "default"
                },
                data: data || {}
            }),
            timeout: 10
        });

        if (response.statusCode !== 200) {
            console.log("FCM send failed:", response.statusCode);
        }
    } catch (err) {
        console.log("FCM send error:", err);
    }
}

onRecordAfterCreateSuccess((e) => {
    const notification = e.record;
    const userId = notification.get("user");

    if (!userId) return;

    try {
        const user = $app.findRecordById("users", userId);
        const fcmToken = user.get("fcm_token");

        if (fcmToken) {
            sendFcmPush(
                fcmToken,
                notification.get("title"),
                notification.get("message"),
                {
                    type: notification.get("type"),
                    target_id: notification.get("target_id") || "",
                    target_type: notification.get("target_type") || "",
                    notification_id: notification.id
                }
            );
        }
    } catch (err) {
        console.log("Failed to send FCM for notification:", err);
    }
}, "notifications");

onRecordAfterCreateSuccess((e) => {
    const answer = e.record;
    const questionId = answer.get("question");

    if (!questionId) return;

    try {
        const question = $app.findRecordById("questions", questionId);
        const authorId = question.get("author");

        if (authorId && authorId !== answer.get("author")) {
            const notificationsCollection = $app.findCollectionByNameOrId("notifications");
            const notification = new Record(notificationsCollection);

            notification.set("user", authorId);
            notification.set("type", "answer");
            notification.set("title", "새 답변");
            notification.set("message", "회원님의 질문에 새 답변이 달렸습니다.");
            notification.set("target_id", questionId);
            notification.set("target_type", "question");
            notification.set("is_read", false);
            notification.set("actor", answer.get("author"));

            $app.save(notification);
        }
    } catch (err) {
        console.log("Failed to create answer notification:", err);
    }
}, "answers");

onRecordAfterCreateSuccess((e) => {
    const comment = e.record;
    const postId = comment.get("post");

    if (!postId) return;

    try {
        const post = $app.findRecordById("community_posts", postId);
        const authorId = post.get("author");

        if (authorId && authorId !== comment.get("author")) {
            const notificationsCollection = $app.findCollectionByNameOrId("notifications");
            const notification = new Record(notificationsCollection);

            notification.set("user", authorId);
            notification.set("type", "comment");
            notification.set("title", "새 댓글");
            notification.set("message", "회원님의 게시글에 새 댓글이 달렸습니다.");
            notification.set("target_id", postId);
            notification.set("target_type", "post");
            notification.set("is_read", false);
            notification.set("actor", comment.get("author"));

            $app.save(notification);
        }
    } catch (err) {
        console.log("Failed to create comment notification:", err);
    }
}, "comments");

onRecordAfterCreateSuccess((e) => {
    const follow = e.record;
    const followingId = follow.get("following");
    const followerId = follow.get("follower");

    if (!followingId || !followerId) return;

    try {
        const follower = $app.findRecordById("users", followerId);
        const followerName = follower.get("name") || "회원";

        const notificationsCollection = $app.findCollectionByNameOrId("notifications");
        const notification = new Record(notificationsCollection);

        notification.set("user", followingId);
        notification.set("type", "follow");
        notification.set("title", "새 팔로워");
        notification.set("message", followerName + "님이 회원님을 팔로우합니다.");
        notification.set("target_id", followerId);
        notification.set("target_type", "user");
        notification.set("is_read", false);
        notification.set("actor", followerId);

        $app.save(notification);
    } catch (err) {
        console.log("Failed to create follow notification:", err);
    }
}, "follows");
