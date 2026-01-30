/// <reference path="../pb_data/types.d.ts" />

const PUSH_FUNCTION_URL = $os.getenv("PUSH_FUNCTION_URL") || "";
const WEBHOOK_SECRET = $os.getenv("WEBHOOK_SECRET") || "";

function sendFcmPush(fcmToken, title, body, data) {
    if (!PUSH_FUNCTION_URL || !fcmToken) {
        return;
    }

    try {
        const headers = {
            "Content-Type": "application/json"
        };

        if (WEBHOOK_SECRET) {
            headers["Authorization"] = "Bearer " + WEBHOOK_SECRET;
        }

        const response = $http.send({
            url: PUSH_FUNCTION_URL,
            method: "POST",
            headers: headers,
            body: JSON.stringify({
                fcmToken: fcmToken,
                title: title,
                body: body,
                data: data || {}
            }),
            timeout: 15
        });

        if (response.statusCode !== 200) {
            console.log("Push function failed:", response.statusCode, response.raw);
        }
    } catch (err) {
        console.log("Push function error:", err);
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

onRecordAfterCreateSuccess((e) => {
    const like = e.record;
    const userId = like.get("user");
    const targetId = like.get("target_id");
    const targetType = like.get("target_type");

    if (!userId || !targetId || !targetType) return;

    try {
        let collectionName = "";
        let authorField = "author";
        
        if (targetType === "post") {
            collectionName = "community_posts";
        } else if (targetType === "comment") {
            collectionName = "comments";
        } else if (targetType === "answer") {
            collectionName = "answers";
        }

        if (!collectionName) return;

        const target = $app.findRecordById(collectionName, targetId);
        const currentCount = target.getInt("like_count") || 0;
        target.set("like_count", currentCount + 1);
        $app.save(target);

        const authorId = target.get(authorField);
        if (authorId && authorId !== userId) {
            const liker = $app.findRecordById("users", userId);
            const likerName = liker.get("name") || "회원";

            const notificationsCollection = $app.findCollectionByNameOrId("notifications");
            const notification = new Record(notificationsCollection);

            let message = "";
            let notifTargetType = targetType;
            let notifTargetId = targetId;

            if (targetType === "post") {
                message = likerName + "님이 회원님의 게시글을 좋아합니다.";
            } else if (targetType === "comment") {
                message = likerName + "님이 회원님의 댓글을 좋아합니다.";
                const postId = target.get("post");
                if (postId) {
                    notifTargetType = "post";
                    notifTargetId = postId;
                }
            } else if (targetType === "answer") {
                message = likerName + "님이 회원님의 답변을 좋아합니다.";
                const questionId = target.get("question");
                if (questionId) {
                    notifTargetType = "question";
                    notifTargetId = questionId;
                }
            }

            notification.set("user", authorId);
            notification.set("type", "like");
            notification.set("title", "좋아요");
            notification.set("message", message);
            notification.set("target_id", notifTargetId);
            notification.set("target_type", notifTargetType);
            notification.set("is_read", false);
            notification.set("actor", userId);

            $app.save(notification);
        }
    } catch (err) {
        console.log("Failed to handle like:", err);
    }
}, "likes");

onRecordAfterDeleteSuccess((e) => {
    const like = e.record;
    const targetId = like.get("target_id");
    const targetType = like.get("target_type");

    if (!targetId || !targetType) return;

    try {
        let collectionName = "";
        
        if (targetType === "post") {
            collectionName = "community_posts";
        } else if (targetType === "comment") {
            collectionName = "comments";
        } else if (targetType === "answer") {
            collectionName = "answers";
        }

        if (!collectionName) return;

        const target = $app.findRecordById(collectionName, targetId);
        const currentCount = target.getInt("like_count") || 0;
        target.set("like_count", Math.max(0, currentCount - 1));
        $app.save(target);
    } catch (err) {
        console.log("Failed to decrement like count:", err);
    }
}, "likes");
