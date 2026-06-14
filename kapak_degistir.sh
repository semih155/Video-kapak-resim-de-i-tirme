cat > ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# --- OTOMATİK TEMİZLİK ---
MEVCUT_PID=$$
ESKI_SURECLER=$(pgrep -f "kapak_degistir.sh")
for pid in $ESKI_SURECLER; do
    if [ "$pid" != "$MEVCUT_PID" ]; then kill -9 "$pid" 2>/dev/null; fi
done

[ -f "$HOME/.kapak_ayarlari.conf" ] && source "$HOME/.kapak_ayarlari.conf"
ISLENENLER_LISTESI="$HOME/.islenenler.txt"
touch "$ISLENENLER_LISTESI"

PREFIX="〖ذال فیلم تقدیم میکندょ〗"
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; MAGENTA='\033[1;35m'; CYAN='\033[1;36m'; RESET='\033[0m'

_ilerleme_goster() {
    local yuzde=$(( $1 * 100 / $2 ))
    printf "\r  ${CYAN}[Hızlandırılmış İşlem] ${YELLOW}%d%% ${MAGENTA}(%d/%d)${RESET}" "$yuzde" "$1" "$2"
}

ana_menu() {
    clear
    echo -e "${MAGENTA}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${MAGENTA}│${YELLOW}    👑   SAMIULLAH DILSUZ PRODUCTION   👑   ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}├────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${MAGENTA}│${CYAN}    🚀   HIZLI KAPAK GÜNCELLEME MODU             ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}└────────────────────────────────────────────────────────┘${RESET}"
    read -p "  Video Klasör Yolu: " g_klasor
    [ ! -d "$g_klasor" ] && { echo -e "  ${RED}✗ Klasör bulunamadı!${RESET}"; sleep 1; ana_menu; return; }
    
    TEMP_LIST="$HOME/.video_listesi_tmp.txt"
    find "$g_klasor" \( -iname "*.mp4" -o -iname "*.mkv" \) > "$TEMP_LIST" 2>/dev/null
    islencek=$(wc -l < "$TEMP_LIST")
    
    CIKTI_VİDEO_DIR="/sdcard/Download/Kapakli_Videolar"
    mkdir -p "$CIKTI_VİDEO_DIR"

    islem_sayisi=0
    while IFS= read -r video; do
        islem_sayisi=$((islem_sayisi + 1))
        _ilerleme_goster "$islem_sayisi" "$islencek"
        
        # HIZLANDIRILMIŞ KOMUT: 
        # -c copy kullanarak tekrar encode etmiyoruz, sadece kapağı yapıştırıyoruz.
        ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" -map 0 -map 1 -c copy -disposition:v:1 attached_pic "$CIKTI_VİDEO_DIR/${PREFIX}$(basename "$video")" -y -loglevel quiet 2>/dev/null
        
    done < "$TEMP_LIST"
    rm -f "$TEMP_LIST"
    echo -e "\n\n  ${GREEN}✓ İşlem bitti! Videolar Download/Kapakli_Videolar klasöründe.${RESET}"
    read -p "  Çıkış için Enter..." _; exit 0
}
ana_menu
EOF
chmod +x ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh
