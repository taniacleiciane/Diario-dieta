"""Ajusta os arquivos Android gerados pelo `flutter create` para o app de lembretes.

- Ativa o desugaring (exigido pelo flutter_local_notifications).
- Adiciona as permissões e os receivers de notificações agendadas.
- Define o nome do app que aparece no celular.
"""
import pathlib
import re
import sys

ANDROID = pathlib.Path("android/app")
GRADLE = ANDROID / "build.gradle.kts"
MANIFEST = ANDROID / "src/main/AndroidManifest.xml"


def fail(msg: str) -> None:
    print(f"ERRO: {msg}")
    sys.exit(1)


# --- build.gradle.kts -------------------------------------------------------
if not GRADLE.exists():
    fail(f"{GRADLE} não encontrado")
g = GRADLE.read_text(encoding="utf-8")

if "isCoreLibraryDesugaringEnabled" not in g:
    g, n = re.subn(r"compileOptions\s*\{", "compileOptions {\n        isCoreLibraryDesugaringEnabled = true", g, count=1)
    if n == 0:
        fail("bloco compileOptions não encontrado")

if "desugar_jdk_libs" not in g:
    g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'

GRADLE.write_text(g, encoding="utf-8")

# --- AndroidManifest.xml ----------------------------------------------------
if not MANIFEST.exists():
    fail(f"{MANIFEST} não encontrado")
m = MANIFEST.read_text(encoding="utf-8")

perms = [
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.SCHEDULE_EXACT_ALARM",
    "android.permission.VIBRATE",
]
lines = "".join(
    f'    <uses-permission android:name="{p}"/>\n' for p in perms if p not in m
)
if lines:
    m, n = re.subn(r"(<application)", lines + r"\1", m, count=1)
    if n == 0:
        fail("tag <application> não encontrada")

receivers = """
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""
if "ScheduledNotificationReceiver" not in m:
    m, n = re.subn(r"(\s*</application>)", receivers + r"\1", m, count=1)
    if n == 0:
        fail("tag </application> não encontrada")

m = re.sub(r'android:label="[^"]*"', 'android:label="Água"', m, count=1)

MANIFEST.write_text(m, encoding="utf-8")
print("Arquivos Android ajustados com sucesso.")
