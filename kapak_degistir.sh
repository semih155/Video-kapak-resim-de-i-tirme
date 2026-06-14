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

# Neon Renk Seti
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; MAGENTA='\033[1;35m'; CYAN='\033[1;36m'
WHITE='\033[1;37m'; RESET='\033[0m'

_kaydet_ayarlar() {
    echo "VARSAYILAN_KLASOR=\"$VARSAYILAN_KLASOR\"" > "$HOME/.kapak_ayarlari.conf"
    echo "VARSAYILAN_RESIM=\"$VARSAYILAN_RESIM\"" >> "$HOME/.kapak_ayarlari.conf"
    echo "VARSAYILAN_MP3_KLASOR=\"$VARSAYILAN_MP3_KLASOR\"" >> "$HOME/.kapak_ayarlari.conf"
}

_zaten_islendi_mi() {
    local aranan="$1"
    while IFS= read -r satir; do [ "$satir" = "$aranan" ] && return 0; done < "$ISLENENLER_LISTESI"
    return 1
}

_ilerleme_goster() {
    local mevcut=$1; local toplam=$2
    local yuzde=$(( mevcut * 100 / toplam ))
    local dolu=$(( yuzde / 5 )); local bos=$(( 20 - dolu ))
    local bar=""
    for ((i=0; i<dolu; i++)); do bar+="█"; done
    for ((i=0; i<bos; i++));  do bar+="░"; done
    printf "\r  ${CYAN}[${GREEN}%s${CYAN}] ${YELLOW}%3d%% ${MAGENTA}(%d/%d)${RESET}" "$bar" "$yuzde" "$mevcut" "$toplam"
}

mp3_donusturucu_menu() {
    clear
    echo -e "${YELLOW}┌────────────────────────────────────────┐${RESET}"
    echo -e "${YELLOW}│       VİDEO -> MP3 SES MOTORU          │${RESET}"
    echo -e "${YELLOW}└────────────────────────────────────────┘${RESET}"
    read -p "  [ENTER] veya Yeni Klasör Yolu: " girilen_mp3_klasor
    [ -z "$girilen_mp3_klasor" ] && girilen_mp3_klasor="$VARSAYILAN_MP3_KLASOR"
    
    if [ ! -d "$girilen_mp3_klasor" ] || [ -z "$VARSAYILAN_RESIM" ]; then
        echo -e "  ${RED}✗ HATA: Geçersiz klasör veya resim!${RESET}"; sleep 2; ana_menu; return
    fi

    VARSAYILAN_MP3_KLASOR="$girilen_mp3_klasor"; _kaydet_ayarlar
    TEMP_MP3_LIST="$HOME/.mp3_listesi_tmp.txt"
    find "$VARSAYILAN_MP3_KLASOR" \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) > "$TEMP_MP3_LIST" 2>/dev/null
    toplam_mp3=$(wc -l < "$TEMP_MP3_LIST")

    [ "$toplam_mp3" -eq 0 ] && { echo -e "  ${RED}✗ Video yok!${RESET}"; rm -f "$TEMP_MP3_LIST"; sleep 2; ana_menu; return; }

    CIKTI_MP3_DIR="$VARSAYILAN_MP3_KLASOR/MP3_Muzikler"
    mkdir -p "$CIKTI_MP3_DIR"
    
    echo -e "\n  ${GREEN}➔ Dönüştürme başladı...${RESET}"
    mp3_islem_sayisi=0
    while IFS= read -r video; do
        isim=$(basename "$video"); isim_base="${isim%.*}"
        mp3_islem_sayisi=$((mp3_islem_sayisi + 1))
        _ilerleme_goster "$mp3_islem_sayisi" "$toplam_mp3"
        ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" -vn -map 0:a:0 -map 1:v:0 -c:a libmp3lame -b:a 192k -ar 44100 -ac 2 -c:v mjpeg -pix_fmt yuvj420p -disposition:v attached_pic -id3v2_version 3 -metadata title="$isim_base" -metadata album="Zal Film" "$CIKTI_MP3_DIR/${PREFIX}${isim_base}.mp3" -y -loglevel quiet 2>/dev/null
    done < "$TEMP_MP3_LIST"
    rm -f "$TEMP_MP3_LIST"
    echo -e "\n\n  ${GREEN}✓ İşlem tamam!${RESET}"; read -p "  Enter..." _; ana_menu
}

ana_menu() {
    clear
    echo -e "${MAGENTA}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${MAGENTA}│${YELLOW}    👑   SAMIULLAH DILSUZ PRODUCTION   👑   ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}├────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${MAGENTA}│${CYAN}    🎬   VİDEO KAPAK GÜNCELLEME & MP3 CONVERTER          ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}└────────────────────────────────────────────────────────┘${RESET}"
    echo -e "  ${YELLOW}[1]${WHITE} Videoların Kapağını Güncelle${RESET}"
    echo -e "  ${YELLOW}[2]${WHITE} Videoları MP3'e Çevir${RESET}"
    echo -e "  ${YELLOW}[3]${WHITE} Hafıza Temizle${RESET}"
    echo -e "  ${YELLOW}[4]${WHITE} Resim Değiştir${RESET}"
    echo -e "  ${RED}[5]${WHITE} Çıkış${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    read -p "  Seçim [1-5]: " secim

    case $secim in
        1)
            read -p "  Video Klasör Yolu: " g_klasor
            [ ! -d "$g_klasor" ] && { echo -e "  ${RED}✗ HATA!${RESET}"; sleep 1; ana_menu; return; }
            VARSAYILAN_KLASOR="$g_klasor"; _kaydet_ayarlar
            TEMP_LIST="$HOME/.video_listesi_tmp.txt"
            find "$VARSAYILAN_KLASOR" \( -iname "*.mp4" -o -iname "*.mkv" \) > "$TEMP_LIST" 2>/dev/null
            islencek=$(wc -l < "$TEMP_LIST")
            
            islem_sayisi=0
            while IFS= read -r video; do
                _zaten_islendi_mi "$(basename "$video")" && continue
                islem_sayisi=$((islem_sayisi + 1))
                _ilerleme_goster "$islem_sayisi" "$islencek"
                isim=$(basename "$video"); klasor=$(dirname "$video")
                temp_dosya="$klasor/temp_$$_$islem_sayisi.mp4"
                ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" -map 0 -map 1 -c copy -disposition:v:1 attached_pic "$temp_dosya" -y -loglevel quiet 2>/dev/null
                if [ $? -eq 0 ]; then
                    [[ "$isim" == "$PREFIX"* ]] && mv "$temp_dosya" "$video" || { mv "$temp_dosya" "$klasor/${PREFIX}${isim}"; rm -f "$video"; }
                    echo "$isim" >> "$ISLENENLER_LISTESI"
                fi
            done < "$TEMP_LIST"
            rm -f "$TEMP_LIST"; ana_menu ;;
        2) mp3_donusturucu_menu ;;
        3) rm -f "$ISLENENLER_LISTESI" && touch "$ISLENENLER_LISTESI"; echo -e "  ${GREEN}✓ Temizlendi.${RESET}"; sleep 1; ana_menu ;;
        4) read -p "  Resim Yolu: " y_r; [ -f "$y_r" ] && { VARSAYILAN_RESIM="$y_r"; _kaydet_ayarlar; }; ana_menu ;;
        5) exit 0 ;;
        *) ana_menu ;;
    esac
}
ana_menu
EOF
chmod +x ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh
