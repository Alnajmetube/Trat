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
CONFIG_FILE="$INSTALL_DIR/.config.json"
LOCK_FILE="$INSTALL_DIR/$APP_NAME.lock"
BASHRC="$HOME/.bashrc"

DOWNLOAD_URL="https://github.com/Alnajmetube/Trat/releases/download/build-termux-arm64-9/trat_arm64"

START_MARKER="# >>> TRAT SERVICE >>>"
END_MARKER="# <<< TRAT SERVICE <<<"

# ==========================================
# Uninstall
# ==========================================

if [ "$1" = "--uninstall" ]; then

    echo "[+] Uninstalling T.R.A.T..."

    # --------------------------------------
    # إيقاف الخدمة
    # --------------------------------------

    if [ -f "$APP_PATH" ]; then
        echo "[+] Stopping T.R.A.T..."

        pkill -f "$APP_PATH" 2>/dev/null || true

        sleep 1
    fi

    # --------------------------------------
    # إزالة تشغيل الخدمة من bashrc
    # --------------------------------------

    if [ -f "$BASHRC" ]; then
        echo "[+] Removing T.R.A.T from ~/.bashrc..."

        sed -i "/$START_MARKER/,/$END_MARKER/d" "$BASHRC"
    fi

    # --------------------------------------
    # حذف الملفات
    # --------------------------------------

    echo "[+] Removing T.R.A.T files..."

    rm -f "$APP_PATH"
    rm -f "$CONFIG_FILE"
    rm -f "$LOCK_FILE"

    # --------------------------------------
    # حذف مجلد .trat إذا أصبح فارغًا
    # --------------------------------------

    if [ -d "$INSTALL_DIR" ]; then
        rmdir "$INSTALL_DIR" 2>/dev/null || true
    fi

    # --------------------------------------
    # تحديث bashrc
    # --------------------------------------

    if [ -f "$BASHRC" ]; then
        source "$BASHRC"
    fi

    echo ""
    echo "=========================================="
    echo " T.R.A.T uninstalled successfully"
    echo "=========================================="
    echo ""

    exit 0
fi

# ==========================================
# التحقق من المدخلات
# ==========================================

if [ "$#" -ne 4 ] || [ "$1" != "--token" ] || [ "$3" != "--chat_id" ]; then
    echo "Usage:"
    echo ""
    echo "  Install:"
    echo "    bash install.sh --token \"TOKEN\" --chat_id \"CHAT_ID\""
    echo ""
    echo "  Uninstall:"
    echo "    bash install.sh --uninstall"
    echo ""

    exit 1
fi

TOKEN="$2"
CHAT_ID="$4"

if [ -z "$TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "Error: token and chat_id are required."
    exit 1
fi

# ==========================================
# التحقق من Termux
# ==========================================

if [ ! -d "/data/data/com.termux" ]; then
    echo "Error: This installer is designed for Termux."
    exit 1
fi

echo "[+] Installing dependencies..."

# ==========================================
# تثبيت المتطلبات
# ==========================================

pkg update -y >/dev/null 2>&1 || true
pkg install -y wget util-linux >/dev/null 2>&1

if ! command -v wget >/dev/null 2>&1; then
    echo "Error: wget was not installed."
    exit 1
fi

if ! command -v flock >/dev/null 2>&1; then
    echo "Error: flock was not installed."
    exit 1
fi

echo "[+] Dependencies installed."

# ==========================================
# إنشاء مجلد التثبيت
# ==========================================

mkdir -p "$INSTALL_DIR"

# ==========================================
# إيقاف النسخة القديمة
# ==========================================

if [ -f "$APP_PATH" ]; then

    echo "[+] Stopping old instance..."

    pkill -f "$APP_PATH" 2>/dev/null || true

    sleep 1
fi

# ==========================================
# تنزيل Binary
# ==========================================

echo "[+] Downloading $APP_NAME..."

wget -q --show-progress \
    -O "$APP_PATH.tmp" \
    "$DOWNLOAD_URL"

if [ ! -s "$APP_PATH.tmp" ]; then

    rm -f "$APP_PATH.tmp"

    echo "Error: Failed to download $APP_NAME."

    exit 1
fi

mv -f "$APP_PATH.tmp" "$APP_PATH"

chmod +x "$APP_PATH"

echo "[+] $APP_NAME downloaded successfully."

# ==========================================
# تشغيل --install مرة واحدة
# ==========================================

echo "[+] Running initial installation..."

"$APP_PATH" \
    --install \
    --token "$TOKEN" \
    --chat_id "$CHAT_ID"

echo "[+] Initial installation completed."

# ==========================================
# إنشاء ملف Lock
# ==========================================

touch "$LOCK_FILE"

# ==========================================
# تحديث bashrc
# ==========================================

echo "[+] Configuring T.R.A.T service..."

# حذف إعداد قديم
if [ -f "$BASHRC" ]; then
    sed -i "/$START_MARKER/,/$END_MARKER/d" "$BASHRC"
fi

# إضافة الخدمة
cat >> "$BASHRC" <<EOF

$START_MARKER
(
    flock -n 9 || exit 0
    nohup "$APP_PATH" >/dev/null 2>&1 &
) 9>"$LOCK_FILE"
$END_MARKER
EOF

echo "[+] Service added to ~/.bashrc."

# ==========================================
# تشغيل الخدمة الآن
# ==========================================

echo "[+] Starting T.R.A.T in background..."

source "$BASHRC"

# ==========================================
# النتيجة
# ==========================================

echo ""
echo "=========================================="
echo " T.R.A.T installed successfully"
echo "=========================================="
echo ""
echo "Binary:"
echo "  $APP_PATH"
echo ""
echo "Config:"
echo "  $CONFIG_FILE"
echo ""
echo "Service:"
echo "  ~/.bashrc"
echo ""
echo "T.R.A.T is running in background."
echo ""
echo "Uninstall:"
echo "  bash install.sh --uninstall"
echo "=========================================="

