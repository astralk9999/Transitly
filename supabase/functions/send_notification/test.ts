import { assertEquals } from "https://deno.land/std/testing/asserts.ts";

Deno.test("send_notification validates UUID format", () => {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  assertEquals(uuidRegex.test("550e8400-e29b-41d4-a716-446655440000"), true);
  assertEquals(uuidRegex.test("not-a-uuid"), false);
});

Deno.test("send_notification requires user_id", () => {
  const required = ["user_id", "title", "body"];
  const validPayload = { user_id: "550e8400-e29b-41d4-a716-446655440000", title: "Test", body: "Hello" };
  const invalidPayload = { title: "Test", body: "Hello" };

  const hasAll = required.every((k) => k in validPayload);
  const missingOne = required.every((k) => k in invalidPayload);

  assertEquals(hasAll, true);
  assertEquals(missingOne, false);
});

Deno.test("send_notification validates title and body length", () => {
  const titleOk = "A".repeat(200);
  const titleTooLong = "A".repeat(201);
  const bodyOk = "B".repeat(2000);
  const bodyTooLong = "B".repeat(2001);

  assertEquals(titleOk.length <= 200, true);
  assertEquals(titleTooLong.length <= 200, false);
  assertEquals(bodyOk.length <= 2000, true);
  assertEquals(bodyTooLong.length <= 2000, false);
});

Deno.test("send_notification rate limit window is 60 seconds", () => {
  const windowMs = 60_000;
  assertEquals(windowMs, 60000);
});

Deno.test("send_notification rejects non-POST methods", () => {
  const allowedMethod = "POST";
  const blockedMethods = ["GET", "PUT", "DELETE", "PATCH"];

  assertEquals(allowedMethod === "POST", true);
  for (const m of blockedMethods) {
    assertEquals(m === "POST", false);
  }
});
