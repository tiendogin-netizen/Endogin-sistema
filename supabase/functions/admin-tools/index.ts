import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

type Body = {
  action?: string;
  student_id?: string;
  new_email?: string;
  new_password?: string;
};

async function callerIsMaster(req: Request): Promise<boolean> {
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  if (!token) return false;

  const callerClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data: userData, error: userErr } = await callerClient.auth.getUser();
  if (userErr || !userData?.user) return false;

  const { data: staffRow } = await admin
    .from("staff")
    .select("is_master, is_super_admin")
    .eq("auth_user_id", userData.user.id)
    .maybeSingle();

  return Boolean(staffRow?.is_master || staffRow?.is_super_admin);
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return new Response("Método não permitido", { status: 405 });

  if (!(await callerIsMaster(req))) {
    return new Response(JSON.stringify({ ok: false, error: "Só a CS master ou o admin geral podem fazer isso." }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  let body: Body;
  try {
    body = await req.json();
  } catch {
    return new Response("JSON inválido", { status: 400 });
  }

  if (!body.student_id) {
    return new Response(JSON.stringify({ ok: false, error: "Falta student_id" }), {
      status: 422,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { data: student, error: studentErr } = await admin
    .from("students")
    .select("id, auth_user_id, email")
    .eq("id", body.student_id)
    .maybeSingle();

  if (studentErr || !student) {
    return new Response(JSON.stringify({ ok: false, error: "Aluno não encontrado" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (body.action === "update_login") {
    if (!student.auth_user_id) {
      return new Response(
        JSON.stringify({ ok: false, error: "Esse aluno ainda não tem login criado — use o convidar_alunos.py primeiro." }),
        { status: 422, headers: { "Content-Type": "application/json" } },
      );
    }
    const updates: Record<string, unknown> = {};
    if (body.new_email) updates.email = body.new_email;
    if (body.new_password) updates.password = body.new_password;
    if (Object.keys(updates).length === 0) {
      return new Response(JSON.stringify({ ok: false, error: "Nada pra atualizar" }), {
        status: 422,
        headers: { "Content-Type": "application/json" },
      });
    }
    (updates as { email_confirm?: boolean }).email_confirm = true;

    const { error: authErr } = await admin.auth.admin.updateUserById(student.auth_user_id, updates);
    if (authErr) {
      return new Response(JSON.stringify({ ok: false, error: authErr.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }
    if (body.new_email) {
      await admin.from("students").update({ email: body.new_email }).eq("id", student.id);
    }
    return new Response(JSON.stringify({ ok: true }), { status: 200, headers: { "Content-Type": "application/json" } });
  }

  // Criar o acesso do aluno ao Portal.
  //
  // Ate agora so existia "update_login", que exige um usuario ja criado — e a
  // criacao acontecia fora do sistema, por um script (convidar_alunos.py). Por
  // isso os alunos que entram sozinhos pela Cademi ficavam sem nenhuma forma de
  // entrar: o webhook gera um token de link magico que nenhuma tela le, e o
  // e-mail nunca saiu. Com esta acao a CS cria o acesso pela propria ficha.
  if (body.action === "create_login") {
    if (student.auth_user_id) {
      return new Response(
        JSON.stringify({ ok: false, error: "Esse aluno já tem login. Use os campos acima para trocar e-mail ou senha." }),
        { status: 422, headers: { "Content-Type": "application/json" } },
      );
    }
    const email = (body.new_email || student.email || "").trim();
    if (!email) {
      return new Response(
        JSON.stringify({ ok: false, error: "Esse aluno está sem e-mail no cadastro — preencha o e-mail antes de criar o acesso." }),
        { status: 422, headers: { "Content-Type": "application/json" } },
      );
    }
    if (!body.new_password || body.new_password.length < 6) {
      return new Response(
        JSON.stringify({ ok: false, error: "Defina uma senha de pelo menos 6 caracteres." }),
        { status: 422, headers: { "Content-Type": "application/json" } },
      );
    }

    const { data: created, error: createErr } = await admin.auth.admin.createUser({
      email,
      password: body.new_password,
      email_confirm: true,
    });
    if (createErr || !created?.user) {
      return new Response(
        JSON.stringify({ ok: false, error: createErr?.message ?? "Falha ao criar o acesso" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    const { error: linkErr } = await admin
      .from("students")
      .update({ auth_user_id: created.user.id, email })
      .eq("id", student.id);
    if (linkErr) {
      // desfaz o usuario recem-criado: deixa-lo orfao faria a proxima tentativa
      // falhar com "e-mail ja cadastrado" sem que ninguem entenda por que.
      await admin.auth.admin.deleteUser(created.user.id);
      return new Response(JSON.stringify({ ok: false, error: linkErr.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true, email }), { status: 200, headers: { "Content-Type": "application/json" } });
  }

  // Excluir o acesso do aluno ao Portal. Só o login some: o cadastro, o
  // progresso nas aulas, o NPS e o histórico continuam em `students` — quem
  // apaga isso é uma decisão de outra ordem, não um botão na ficha.
  //
  // A ordem importa: solta o vínculo em `students` ANTES de apagar o usuário,
  // porque auth_user_id é chave estrangeira para auth.users. Apagando primeiro,
  // a operação poderia ser recusada (ou levar a linha junto, dependendo da
  // regra de cascata) — e aí sumiria o aluno inteiro, não só o login dele.
  if (body.action === "delete_login") {
    if (!student.auth_user_id) {
      return new Response(
        JSON.stringify({ ok: false, error: "Esse aluno ainda não tem login criado." }),
        { status: 422, headers: { "Content-Type": "application/json" } },
      );
    }

    const { error: unlinkErr } = await admin
      .from("students")
      .update({ auth_user_id: null })
      .eq("id", student.id);
    if (unlinkErr) {
      return new Response(JSON.stringify({ ok: false, error: unlinkErr.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { error: delErr } = await admin.auth.admin.deleteUser(student.auth_user_id);
    if (delErr) {
      // devolve o vínculo: sem isso o aluno ficaria com login funcionando e o
      // cadastro sem saber disso, que é pior que o estado original.
      await admin.from("students").update({ auth_user_id: student.auth_user_id }).eq("id", student.id);
      return new Response(JSON.stringify({ ok: false, error: delErr.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true }), { status: 200, headers: { "Content-Type": "application/json" } });
  }

  if (body.action === "get_login_link") {
    const { data: linkData, error: linkErr } = await admin.auth.admin.generateLink({
      type: "magiclink",
      email: student.email,
    });
    if (linkErr || !linkData) {
      return new Response(JSON.stringify({ ok: false, error: linkErr?.message ?? "Falha ao gerar link" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }
    return new Response(
      JSON.stringify({ ok: true, action_link: linkData.properties?.action_link ?? null }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  }

  return new Response(JSON.stringify({ ok: false, error: "Ação desconhecida" }), {
    status: 400,
    headers: { "Content-Type": "application/json" },
  });
});
