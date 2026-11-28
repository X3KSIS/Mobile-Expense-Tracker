// Signs in with a username and password.
//
// Supabase Auth signs in by email only. This function finds the account
// behind the username with the service role, signs in on the server and
// returns just the refresh token; the app turns it into a session with
// auth.setSession. The email never leaves the server, and a wrong
// username fails the same way (and takes about as long) as a wrong
// password, so usernames can't be probed.
//
// Deploy with "Verify JWT" OFF: callers are not signed in yet.
// Request:  POST { "username": "paul_m", "password": "..." }
// Response: 200 { "refresh_token": "..." }
//           400 { "error": "invalid_credentials" | "email_not_confirmed" |
//                          "bad_request" }
//           429 { "error": "too_many_requests" }

import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const reply = (status: number, body: Record<string, string>) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

const usernamePattern = /^[a-z0-9_.]{3,20}$/;

// Used when the username doesn't exist, so the failure takes as long as a
// wrong password would.
const nobody = "nobody@invalid.example";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply(405, { error: "bad_request" });

  let username = "";
  let password = "";
  try {
    const body = await req.json();
    username = String(body?.username ?? "").trim().toLowerCase();
    password = String(body?.password ?? "");
  } catch {
    return reply(400, { error: "bad_request" });
  }
  if (!usernamePattern.test(username) || password.length === 0) {
    return reply(400, { error: "invalid_credentials" });
  }

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const options = { auth: { persistSession: false, autoRefreshToken: false } };
  const admin = createClient(url, serviceKey, options);

  let email = nobody;
  const { data: profile } = await admin
    .from("profiles")
    .select("user_id")
    .eq("username", username)
    .maybeSingle();
  if (profile?.user_id) {
    const { data } = await admin.auth.admin.getUserById(profile.user_id);
    if (data?.user?.email) email = data.user.email;
  }

  // A separate client, so the admin client never holds a user session.
  const signer = createClient(
    url,
    Deno.env.get("SUPABASE_ANON_KEY") ?? serviceKey,
    options,
  );
  const { data, error } = await signer.auth.signInWithPassword({
    email,
    password,
  });
  if (error || !data.session || email === nobody) {
    if (error?.status === 429) {
      return reply(429, { error: "too_many_requests" });
    }
    const code = email !== nobody && error?.code === "email_not_confirmed"
      ? "email_not_confirmed"
      : "invalid_credentials";
    return reply(400, { error: code });
  }
  return reply(200, { refresh_token: data.session.refresh_token });
});
