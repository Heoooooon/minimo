/// <reference path="../pb_data/types.d.ts" />

// Debug endpoint to check collection
routerAdd("GET", "/api/custom/debug", (e) => {
    try {
        const collection = $app.findCollectionByNameOrId("verification_codes");
        const fields = collection.fields || [];
        const fieldNames = [];
        for (let i = 0; i < fields.length; i++) {
            fieldNames.push(fields[i].name);
        }
        return e.json(200, {
            collectionName: collection.name,
            collectionId: collection.id,
            fieldNames: fieldNames
        });
    } catch (err) {
        return e.json(500, { error: String(err) });
    }
});

// 인증 코드 발송 API
routerAdd("POST", "/api/custom/send-code", (e) => {
    try {
        const data = e.requestInfo().body;
        const email = data.email || "";

        if (!email) {
            throw new BadRequestError("이메일이 필요합니다.");
        }

        // Generate 4-digit code inline
        const code = String(Math.floor(1000 + Math.random() * 9000));
        const expiresAt = new Date(Date.now() + 3 * 60 * 1000);

        // Find collection
        const collection = $app.findCollectionByNameOrId("verification_codes");

        // Create record
        const record = new Record(collection);
        record.set("email", email);
        record.set("code", code);
        record.set("expires_at", expiresAt.toISOString());
        record.set("verified", false);

        // Save
        $app.save(record);

        // Send email
        const message = new MailerMessage({
            from: {
                address: $app.settings().meta.senderAddress,
                name: $app.settings().meta.senderName || "우물",
            },
            to: [{ address: email }],
            subject: "[우물] 이메일 인증번호",
            html: "<div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 40px 20px;'>" +
                  "<h1 style='color: #0165FE; font-size: 24px; margin-bottom: 30px;'>우물 이메일 인증</h1>" +
                  "<p style='font-size: 16px; color: #333; margin-bottom: 20px;'>안녕하세요! 우물 회원가입을 위한 인증번호입니다.</p>" +
                  "<div style='background: #F5F7FA; border-radius: 12px; padding: 30px; text-align: center; margin: 30px 0;'>" +
                  "<p style='font-size: 14px; color: #666; margin-bottom: 10px;'>인증번호</p>" +
                  "<p style='font-size: 36px; font-weight: bold; color: #0165FE; letter-spacing: 8px; margin: 0;'>" + code + "</p>" +
                  "</div>" +
                  "<p style='font-size: 14px; color: #999;'>이 인증번호는 3분간 유효합니다.<br>본인이 요청하지 않았다면 이 이메일을 무시해주세요.</p>" +
                  "</div>",
        });

        $app.newMailClient().send(message);

        return e.json(200, {
            success: true,
            message: "인증 코드가 발송되었습니다."
        });
    } catch (err) {
        return e.json(500, { error: String(err), message: "Failed" });
    }
});

// 인증 코드 검증 API
routerAdd("POST", "/api/custom/verify-code", (e) => {
    const data = e.requestInfo().body;
    const email = data.email || "";
    const code = data.code || "";

    if (!email || !code) {
        throw new BadRequestError("이메일과 인증 코드가 필요합니다.");
    }

    // 인증 코드 조회 - try-catch로 레코드 없는 경우 처리
    let record;
    try {
        record = $app.findFirstRecordByFilter("verification_codes",
            "email = {:email} && code = {:code} && verified = false",
            { email: email, code: code }
        );
    } catch (err) {
        // 레코드를 찾지 못한 경우
        throw new BadRequestError("유효하지 않은 인증 코드입니다.");
    }

    if (!record) {
        throw new BadRequestError("유효하지 않은 인증 코드입니다.");
    }

    const expiresAt = new Date(record.get("expires_at"));

    if (new Date() > expiresAt) {
        $app.delete(record);
        throw new BadRequestError("인증 코드가 만료되었습니다.");
    }

    record.set("verified", true);
    $app.save(record);

    return e.json(200, { success: true, message: "인증이 완료되었습니다." });
});
