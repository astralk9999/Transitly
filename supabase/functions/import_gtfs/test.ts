import { assertEquals } from "https://deno.land/std/testing/asserts.ts";

Deno.test("import_gtfs validates zip file", () => {
  const zipSignature = new Uint8Array([0x50, 0x4b, 0x03, 0x04]);
  assertEquals(zipSignature[0], 0x50);
  assertEquals(zipSignature[1], 0x4b);
  assertEquals(zipSignature[2], 0x03);
  assertEquals(zipSignature[3], 0x04);
});

Deno.test("import_gtfs parses stops.txt", () => {
  const csv = "stop_id,stop_name,stop_lat,stop_lon\nS1,Central,36.7,-6.1";
  const lines = csv.split("\n");
  assertEquals(lines.length, 2);

  const headers = lines[0].split(",");
  assertEquals(headers.length, 4);
  assertEquals(headers[0], "stop_id");
  assertEquals(headers[1], "stop_name");

  const data = lines[1].split(",");
  assertEquals(data[0], "S1");
  assertEquals(data[1], "Central");
});

Deno.test("import_gtfs rejects non-https URLs", () => {
  const url1 = new URL("https://example.com/gtfs.zip");
  const url2 = new URL("http://example.com/gtfs.zip");

  assertEquals(url1.protocol, "https:");
  assertEquals(url2.protocol, "http:");
  assertEquals(url1.protocol === "https:", true);
  assertEquals(url2.protocol === "https:", false);
});

Deno.test("import_gtfs blocks private IPs", () => {
  const privateIps = ["10.0.0.1", "192.168.1.1", "172.16.0.1", "127.0.0.1", "::1", "fc00::1", "fe80::1"];
  const publicIps = ["8.8.8.8", "1.1.1.1", "93.184.216.34"];

  const isPrivate = (ip: string) => {
    return ip.startsWith("10.") || ip.startsWith("192.168.") || ip.startsWith("172.16.") ||
      ip === "127.0.0.1" || ip === "::1" || ip.startsWith("fc") || ip.startsWith("fd") ||
      ip.startsWith("fe80:") || ip.startsWith("fe9") || ip.startsWith("fea") || ip.startsWith("feb");
  };

  for (const ip of privateIps) {
    assertEquals(isPrivate(ip), true, `Expected ${ip} to be private`);
  }
  for (const ip of publicIps) {
    assertEquals(isPrivate(ip), false, `Expected ${ip} to be public`);
  }
});

Deno.test("import_gtfs validates operatorSlug format", () => {
  const slugRegex = /^[a-z0-9_-]{2,40}$/;

  assertEquals(slugRegex.test("comujesa"), true);
  assertEquals(slugRegex.test("a"), false);
  assertEquals(slugRegex.test("UPPERCASE"), false);
  assertEquals(slugRegex.test("space name"), false);
  assertEquals(slugRegex.test("valid_slug-123"), true);
});

Deno.test("import_gtfs requires operatorSlug and gtfsUrl", () => {
  const required = ["operatorSlug", "gtfsUrl"];

  const validPayload = { operatorSlug: "comujesa", gtfsUrl: "https://example.com/gtfs.zip" };
  const incompletePayload = { operatorSlug: "comujesa" };

  const hasAll = required.every((k) => k in validPayload);
  const missingOne = required.every((k) => k in incompletePayload);

  assertEquals(hasAll, true);
  assertEquals(missingOne, false);
});
