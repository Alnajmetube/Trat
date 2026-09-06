import asyncio
import html
import json
import os
import sys
# telegarm bot impoets
from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes, MessageHandler, filters
from telegram.error import NetworkError

CONFIG_FILE = ".config.json"
TOKEN = None
CHAT_ID = None

def install(token: str, chat_id: str):
    config = {
        "token": token,
        "chat_id": str(chat_id)
    }

    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(config, f, ensure_ascii=False, indent=4)

    print("✅ installation completed successfully.")

def load_config():
    global TOKEN, CHAT_ID

    if not os.path.isfile(CONFIG_FILE):
        print("❌ البرنامج غير مثبت.")
        print('استخدم: script.py --install --token "TOKEN" --chat_id "CHAT_ID"')
        sys.exit(1)

    with open(CONFIG_FILE, "r", encoding="utf-8") as f:
        config = json.load(f)

    TOKEN = config["token"]
    CHAT_ID = str(config["chat_id"])

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_chat.id != CHAT_ID:
        return
    message = (
        "🟢 الجهاز يعمل بنجاح"
    )

    await update.message.reply_text(
        message,
        parse_mode="HTML"
    )

async def run_command(command: str) -> str:
    process = await asyncio.create_subprocess_shell(
        command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.STDOUT,
    )

    output, _ = await process.communicate()

    return output.decode("utf-8", errors="replace")

async def run_command_handler(
    update: Update,
    context: ContextTypes.DEFAULT_TYPE
):
    if update.effective_chat.id != CHAT_ID:
        return

    if not context.args:
        await update.message.reply_text(
            "❌ الاستخدام:\n"
            "<code>/run command</code>",
            parse_mode="HTML"
        )
        return

    command = " ".join(context.args)

    try:
        result = await run_command(command)

        if not result:
            result = "(no output)"

        result = html.escape(result)

        await update.message.reply_text(
            "🖥️ <b>ناتج الامر</b>\n"
            "━━━━━━━━━━━━━━━━━━\n"
            f"<pre>{result}</pre>",
            parse_mode="HTML"
        )

    except NetworkError as exc:
        print(f"[Telegram] Failed to send result: {exc}")

    except Exception as exc:
        print(
            f"[run] Handler error: "
            f"{type(exc).__name__}: {exc}"
        )



async def upload_command_handl(update: Update, context: ContextTypes.DEFAULT_TYPE):

    if update.effective_chat.id != CHAT_ID:
        return

    if not context.args:
        await update.message.reply_text(
            'الاستخدام:\n/upload "file_path"'
        )
        return

    file_path = " ".join(context.args).strip().strip('"').strip("'")

    if not os.path.isfile(file_path):
        await update.message.reply_text("❌ الملف غير موجود.")
        return

    try:
        with open(file_path, "rb") as file:
            await update.message.reply_document(
                document=file,
                caption="تم رفع الملف ✅"
            )

    except Exception as e:
        await update.message.reply_text(f"❌ حدث خطأ:\n{e}")

async def post_init(application):
    await application.bot.send_message(
        chat_id=CHAT_ID,
        text="🟢 الجهاز متصل"
    )

def main():
    if "--install" in sys.argv:
        try:
            token = sys.argv[sys.argv.index("--token") + 1]
            chat_id = sys.argv[sys.argv.index("--chat_id") + 1]
        except (ValueError, IndexError):
            #in english
            print(
                '❌ Usage:\n'
                'Trat--install --token "TOKEN" --chat_id "'
            )
            return

        install(token, chat_id)
        return

    load_config()
    application = (
        ApplicationBuilder()
        .token(TOKEN)
        .post_init(post_init)
        .build()
    )

    start_handler = CommandHandler('start', start)
    application.add_handler(start_handler)

    application.add_handler(CommandHandler('run', run_command_handler))
    application.add_handler(
        CommandHandler("up", upload_command_handl)
    )
    application.run_polling()



if __name__ == '__main__':
    asyncio.run(main())