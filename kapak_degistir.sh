cat > ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# --- OTOMATİK TEMİZLİK (CTRL+Z KALINTILARI İÇİN) ---
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

ana_menu() {
    clear
    echo -e "${MAGENTA}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${MAGENTA}│${YELLOW}    👑   SAMIULLAH DILSUZ PRODUCTION   👑   ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}├────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${MAGENTA}│${CYAN}    🎬   VİDEO KAPAK GÜNCELLEME MOTORU                   ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}└────────────────────────────────────────────────────────┘${RESET}"
    echo -e "  ${CYAN}Aktif Resim :${GREEN} ${VARSAYILAN_RESIM:-'Ayarlanmamış'}${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${YELLOW}[1]${WHITE} Videoların Kapağını Güncelle ${MAGENTA}(Alt Klasörler Dahil)${RESET}"
    echo -e "  ${YELLOW}[2]${WHITE} Hafıza Geçmişini Temizle    ${RED}(Baştan İşleme Alır)${RESET}"
    echo -e "  ${YELLOW}[3]${WHITE} Kapak Resmini Değiştir      ${YELLOW}(Yeni Resim Seçimi)${RESET}"
    echo -e "  ${RED}[4]${WHITE} Güvenli Çıkış${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    read -p "  Seçiminiz [1-4]: " secim

    case $secim in
        1)
            if [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then
                echo -e "  ${RED}✗ HATA: Önce resim seçin (Seçenek 3)!${RESET}"; sleep 2; ana_menu; return
            fi
            echo ""
            read -p "  [ENTER] veya Video Klasör Yolu: " girilen_klasor
            [ -z "$girilen_klasor" ] && girilen_klasor="$VARSAYILAN_KLASOR"
            if [ -z "$girilen_klasor" ] || [ ! -d "$girilen_klasor" ]; then
                echo -e "  ${RED}✗ HATA: Klasör bulunamadı!${RESET}"; sleep 2; ana_menu; return
            fi

            VARSAYILAN_KLASOR="$girilen_klasor"; _kaydet_ayarlar
            TEMP_LIST="$HOME/.video_listesi_tmp.txt"
            
            # Hem MP4 hem MKV uzantılı tüm alt klasörleri tarar
            find "$VARSAYILAN_KLASOR" \( -iname "*.mp4" -o -iname "*.mkv" \) > "$TEMP_LIST" 2>/dev/null
            toplam=$(wc -l < "$TEMP_LIST")

            if [ "$toplam" -eq 0 ]; then
                echo -e "  ${RED}✗ Klasörde video yok!${RESET}"; rm -f "$TEMP_LIST"; sleep 2; ana_menu; return
            fi

            zaten=0
            while IFS= read -r video; do
                _zaten_islendi_mi "$(basename "$video")" && zaten=$((zaten + 1))
            done < "$TEMP_LIST"
            islencek=$((toplam - zaten))

            clear
            echo -e "${CYAN}┌────────────────────────────────────────┐${RESET}"
            echo -e "${CYAN}│           KAPAK İŞLEMİ BAŞLADI         │${RESET}"
            echo -e "${CYAN}└────────────────────────────────────────┘${RESET}"
            echo -e "  ${CYAN}Toplam :${YELLOW} $toplam${RESET}  |  ${CYAN}Kalan :${MAGENTA} $islencek${RESET}  |  ${CYAN}Atlanan :${BLUE} $zaten${RESET}"
            echo -e "${CYAN}──────────────────────────────────────────${RESET}"

            if [ "$islencek" -eq 0 ]; then
                echo -e "  ${GREEN}✓ Tüm videolar zaten yapılmış!${RESET}"; rm -f "$TEMP_LIST"; read -p "  Enter..." _; ana_menu; return
            fi

            islem_sayisi=0; hata_sayisi=0
            while IFS= read -r video; do
                isim=$(basename "$video"); klasor=$(dirname "$video")
                _zaten_islendi_mi "$isim" && continue

                islem_sayisi=$((islem_sayisi + 1))
                _ilerleme_goster "$islem_sayisi" "$islencek"

                # KOPYALAMA YOK! Videonun olduğu klasörde gizli temp dosya oluşturulur
                temp_dosya="$klasor/temp_${MEVCUT_PID}_${islem_sayisi}.mp4"
                
                ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" -map 0 -map 1 -c copy -disposition:v:1 attached_pic "$temp_dosya" -y -loglevel quiet 2>/dev/null

                if [ $? -eq 0 ]; then
                    if [[ "$isim" == "$PREFIX"* ]]; then
                        mv "$temp_dosya" "$video" 2>/dev/null; yeni_isim="$isim"
                    else
                        yeni_isim="${PREFIX}${isim}"
                        mv "$temp_dosya" "$klasor/$yeni_isim" 2>/dev/null; rm -f "$video"
                    fi
                    echo "$yeni_isim" >> "$ISLENENLER_LISTESI"
                else
                    rm -f "$temp_dosya"; hata_sayisi=$((hata_sayisi + 1))
                fi
            done < "$TEMP_LIST"
            rm -f "$TEMP_LIST"

            echo -e "\n\n${GREEN}┌── İŞLEM ÖZETİ ─────────────────────────┐${RESET}"
            echo -e "  ${GREEN}✓ Tamamlanan : $islem_sayisi Video${RESET}"
            echo -e "  ${RED}✗ Hatalı     : $hata_sayisi Video${RESET}"
            echo -e "${GREEN}└────────────────────────────────────────┘${RESET}"
            read -p "  Enter'a bas..." _
            ana_menu
            ;;
        2)
            read -p "  Hafıza temizlensin mi? (e/h): " onay
            if [[ "$onay" == "e" || "$onay" == "E" ]]; then
                rm -f "$ISLENENLER_LISTESI" && touch "$ISLENENLER_LISTESI"
                echo -e "  ${GREEN}✓ Hafıza sıfırlandı.${RESET}"
            fi
            sleep 1; ana_menu ;;
        3)
            echo ""
            read -p "  Yeni Resim Tam Yolu: " yeni_r
            if [ -f "$yeni_r" ]; then
                VARSAYILAN_RESIM="$yeni_r"; _kaydet_ayarlar
                echo -e "  ${GREEN}✓ Kapak güncellendi.${RESET}"
            else
                echo -e "  ${RED}✗ Dosya bulunamadı!${RESET}"
            fi
            sleep 1; ana_menu ;;
        4) exit 0 ;;
        *) ana_menu ;;
    esac
}

ana_menu
EOF
chmod +x ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh
