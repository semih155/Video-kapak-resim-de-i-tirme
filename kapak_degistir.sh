cat > ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

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
    while IFS= read -r satir; do
        [ "$satir" = "$aranan" ] && return 0
    done < "$ISLENENLER_LISTESI"
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

adlandirma_menu() {
    while true; do
        clear
        echo -e "${CYAN}┌────────────────────────────────────────┐${RESET}"
        echo -e "${CYAN}│        KLASÖR SEÇİMİ MENÜSÜ            │${RESET}"
        echo -e "${CYAN}└────────────────────────────────────────┘${RESET}"
        echo -e "  ${YELLOW}[1]${CYAN} VidMate İndirilenleri${RESET}"
        echo -e "  ${YELLOW}[2]${CYAN} SnapTube İndirilenleri${RESET}"
        echo -e "  ${YELLOW}[3]${CYAN} VidMate & SnapTube Birlikte${RESET}"
        echo -e "  ${YELLOW}[4]${CYAN} Telegram Videoları${RESET}"
        echo -e "  ${YELLOW}[5]${CYAN} Tüm Müzik Dosyaları${RESET}"
        echo -e "  ${YELLOW}[6]${CYAN} Özel Klasör Yolu${RESET}"
        echo -e "  ${RED}[0]${MAGENTA} Ana Menüye Dön${RESET}"
        echo -e "${CYAN}──────────────────────────────────────────${RESET}"
        read -p "  Seçim [0-6]: " choice

        case "$choice" in
            1) DIRS=("/storage/emulated/0/VidMate/download"); MODE_TYPE="video" ;;
            2) DIRS=("/storage/emulated/0/snaptube/download/SnapTube Video"); MODE_TYPE="video" ;;
            3) DIRS=("/storage/emulated/0/VidMate/download" "/storage/emulated/0/snaptube/download/SnapTube Video"); MODE_TYPE="video" ;;
            4) DIRS=("/storage/emulated/0/Android/media/org.telegram.messenger/Telegram/Telegram Video"); MODE_TYPE="video" ;;
            5) MODE_TYPE="music" ;;
            6) read -p "  Yol: " custom_dir; DIRS=("$custom_dir"); MODE_TYPE="video" ;;
            0) ana_menu; return ;;
            *) echo -e "  ${RED}✗ Geçersiz!${RESET}"; sleep 1; continue ;;
        esac

        echo -e "\n${MAGENTA}┌── MOD SEÇİMİ ──────────────────────────┐${RESET}"
        echo -e "  ${YELLOW}[1]${GREEN} Prefix Ekle${RESET}"
        echo -e "  ${YELLOW}[2]${RED} Metin Kaldır${RESET}"
        echo -e "  ${RED}[0]${MAGENTA} İptal Et${RESET}"
        echo -e "${MAGENTA}└────────────────────────────────────────┘${RESET}"
        read -p "  Seçim [0-2]: " op_mode

        case "$op_mode" in
            1) MODE_OP="add" ;;
            2) MODE_OP="remove" ;;
            0) ana_menu; return ;;
            *) echo -e "  ${RED}✗ Geçersiz!${RESET}"; sleep 1; continue ;;
        esac

        if [[ "$MODE_OP" != "add" ]]; then
            read -p "  Kaldırılacak metin: " text_to_remove
            [[ -z "$text_to_remove" ]] && { echo -e "  ${RED}✗ Metin boş!${RESET}"; sleep 1; continue; }
        fi

        processed=0; skipped=0; failed=0

        process_file(){
            local f="$1"; local base="$(basename "$f")"
            case "$base" in *.nomedia|*.txt|*.json) ((skipped++)); return ;; esac
            
            if [[ "$MODE_OP" == "add" ]]; then
                if [[ "$base" == "$PREFIX"* ]]; then
                    ((skipped++)); return
                fi
                if mv -- "$f" "$(dirname "$f")/$PREFIX$base" 2>/dev/null; then
                    ((processed++))
                else
                    ((failed++))
                fi
            else
                if [[ "$base" == *"$text_to_remove"* ]]; then
                    local cleaned="${base//$text_to_remove/}"
                    if mv -- "$f" "$(dirname "$f")/$cleaned" 2>/dev/null; then
                        ((processed++))
                    else
                        ((failed++))
                    fi
                else
                    ((skipped++))
                fi
            fi
        }

        echo -e "\n  ${YELLOW}➔ Tarama ve düzeltme başladı...${RESET}"
        if [[ "$MODE_TYPE" == "video" ]]; then
            for d in "${DIRS[@]}"; do
                [ ! -d "$d" ] && continue
                while IFS= read -r -d '' file; do process_file "$file"; done < <(find "$d" -maxdepth 1 -type f -print0 2>/dev/null)
            done
        else
            while IFS= read -r -d '' file; do process_file "$file"; done < <(find /storage/emulated/0 -path "/storage/emulated/0/Android" -prune -o -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.m4a" \) -print0 2>/dev/null)
        fi

        echo -e "\n${GREEN}┌── ÖZET RAPOR ──────────────────────────┐${RESET}"
        echo -e "  ${GREEN}✓ Başarılı : $processed${RESET}"
        echo -e "  ${BLUE}→ Atlanan  : $skipped${RESET}"
        echo -e "  ${RED}✗ Hatalı   : $failed${RESET}"
        echo -e "${GREEN}└────────────────────────────────────────┘${RESET}"
        read -p $'\n  Devam etmek için Enter...' _
        ana_menu; return
    done
}

mp3_donusturucu_menu() {
    clear
    echo -e "${YELLOW}┌────────────────────────────────────────┐${RESET}"
    echo -e "${YELLOW}│       VİDEO -> MP3 SES MOTORU          │${RESET}"
    echo -e "${YELLOW}└────────────────────────────────────────┘${RESET}"
    echo -e "  ${CYAN}Klasör :${MAGENTA} ${VARSAYILAN_MP3_KLASOR:-'Boş'}${RESET}"
    echo -e "  ${CYAN}Kapak  :${GREEN} ${VARSAYILAN_RESIM:-'Seçilmemiş'}${RESET}"
    echo -e "${YELLOW}──────────────────────────────────────────${RESET}"
    read -p "  [ENTER] veya Yeni Yol: " girilen_mp3_klasor

    [ -z "$girilen_mp3_klasor" ] && girilen_mp3_klasor="$VARSAYILAN_MP3_KLASOR"
    if [ -z "$girilen_mp3_klasor" ] || [ ! -d "$girilen_mp3_klasor" ]; then
        echo -e "  ${RED}✗ HATA: Geçersiz klasör!${RESET}"; sleep 2; ana_menu; return
    fi
    if [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then
        echo -e "  ${RED}✗ HATA: Önce kapak resmi seçin!${RESET}"; sleep 2; ana_menu; return
    fi

    VARSAYILAN_MP3_KLASOR="$girilen_mp3_klasor"; _kaydet_ayarlar
    TEMP_MP3_LIST="$HOME/.mp3_listesi_tmp.txt"
    find "$VARSAYILAN_MP3_KLASOR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) > "$TEMP_MP3_LIST" 2>/dev/null
    toplam_mp3=$(wc -l < "$TEMP_MP3_LIST")

    if [ "$toplam_mp3" -eq 0 ]; then
        echo -e "  ${RED}✗ Dönüştürülecek video bulunamadı!${RESET}"; rm -f "$TEMP_MP3_LIST"; sleep 2; ana_menu; return
    fi

    CIKTI_MP3_DIR="$VARSAYILAN_MP3_KLASOR/MP3_Muzikler"
    mkdir -p "$CIKTI_MP3_DIR"

    clear
    echo -e "${GREEN}┌────────────────────────────────────────┐${RESET}"
    echo -e "${GREEN}│        MP3 DÖNÜŞTÜRME BAŞLADI          │${RESET}"
    echo -e "${GREEN}└────────────────────────────────────────┘${RESET}"
    echo -e "  ${CYAN}İşlenecek Dosya :${YELLOW} $toplam_mp3${RESET}"
    echo -e "  ${CYAN}Kapak Durumu    :${GREEN} Kalıcı Olarak Gömülüyor${RESET}"
    echo -e "${GREEN}──────────────────────────────────────────${RESET}"

    mp3_islem_sayisi=0; mp3_hata_sayisi=0

    while IFS= read -r video; do
        isim=$(basename "$video"); isim_base="${isim%.*}"
        [[ "$isim_base" == "$PREFIX"* ]] && temiz_isim="${isim_base#$PREFIX}" || temiz_isim="$isim_base"

        mp3_islem_sayisi=$((mp3_islem_sayisi + 1))
        _ilerleme_goster "$mp3_islem_sayisi" "$toplam_mp3"

        # Garantili ses codec dönüşümü + Teyp uyumlu ID3v2 Kapak Entegrasyonu
        ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" -vn \
            -map 0:a:0 -map 1:v:0 -c:a libmp3lame -b:a 192k -ar 44100 -ac 2 \
            -c:v mjpeg -pix_fmt yuvj420p -disposition:v attached_pic \
            -id3v2_version 3 -metadata title="$temiz_isim" -metadata album="Zal Film" \
            "$CIKTI_MP3_DIR/${PREFIX}${temiz_isim}.mp3" -y -loglevel quiet 2>/dev/null

        [ $? -ne 0 ] && mp3_hata_sayisi=$((mp3_hata_sayisi + 1))
    done < "$TEMP_MP3_LIST"
    rm -f "$TEMP_MP3_LIST"

    echo -e "\n\n${GREEN}┌── İŞLEM SONUCU ────────────────────────┐${RESET}"
    echo -e "  ${GREEN}✓ Dönüştürülen : $((mp3_islem_sayisi - mp3_hata_sayisi)) Müzik${RESET}"
    echo -e "  ${RED}✗ Hata Veren   : $mp3_hata_sayisi Video${RESET}"
    echo -e "${GREEN}└────────────────────────────────────────┘${RESET}"
    read -p "  Ana menü için Enter..." _
    ana_menu
}

ana_menu() {
    clear
    echo -e "${MAGENTA}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${MAGENTA}│${YELLOW}    👑   SAMIULLAH DILSUZ PRODUCTION   👑   ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}├────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${MAGENTA}│${CYAN}    🎬   VİDEO KAPAK GÜNCELLEME & MP3 CONVERTER          ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}└────────────────────────────────────────────────────────┘${RESET}"
    echo -e "  ${CYAN}Aktif Resim :${GREEN} ${VARSAYILAN_RESIM:-'Ayarlanmamış'}${RESET}"
    echo -e "  ${CYAN}Marka Etiket:${BLUE} $PREFIX${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${YELLOW}[1]${WHITE} Videoların Kapağını Güncelle ${MAGENTA}(Hafızalı Yoldan)${RESET}"
    echo -e "  ${YELLOW}[2]${WHITE} Videoları MP3'e Çevir       ${GREEN}(Kapaklı + Hatasız Entegre)${RESET}"
    echo -e "  ${YELLOW}[3]${WHITE} Hafıza Geçmişini Temizle    ${RED}(Baştan İşleme Alır)${RESET}"
    echo -e "  ${YELLOW}[4]${WHITE} Kapak Resmini Değiştir      ${YELLOW}(Yeni Resim Seçimi)${RESET}"
    echo -e "  ${YELLOW}[5]${WHITE} Gelişmiş Adlandırma Menüsü  ${BLUE}(Prefix Yönetimi)${RESET}"
    echo -e "  ${RED}[6]${WHITE} Güvenli Çıkış${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    read -p "  Seçiminiz [1-6]: " secim

    case $secim in
        1)
            if [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then
                echo -e "  ${RED}✗ HATA: Önce resim seçin (Seçenek 4)!${RESET}"; sleep 2; ana_menu; return
            fi
            echo ""
            read -p "  [ENTER] veya Video Klasör Yolu: " girilen_klasor
            [ -z "$girilen_klasor" ] && girilen_klasor="$VARSAYILAN_KLASOR"
            if [ -z "$girilen_klasor" ] || [ ! -d "$girilen_klasor" ]; then
                echo -e "  ${RED}✗ HATA: Klasör bulunamadı!${RESET}"; sleep 2; ana_menu; return
            fi

            VARSAYILAN_KLASOR="$girilen_klasor"; _kaydet_ayarlar
            TEMP_LIST="$HOME/.video_listesi_tmp.txt"
            find "$VARSAYILAN_KLASOR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" \) > "$TEMP_LIST" 2>/dev/null
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

                temp_dosya="$klasor/temp_$$_$islem_sayisi.mp4"
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
        2) mp3_donusturucu_menu ;;
        3)
            read -p "  Hafıza temizlensin mi? (e/h): " onay
            if [[ "$onay" == "e" || "$onay" == "E" ]]; then
                rm -f "$ISLENENLER_LISTESI" && touch "$ISLENENLER_LISTESI"
                echo -e "  ${GREEN}✓ Hafıza sıfırlandı.${RESET}"
            fi
            sleep 1; ana_menu ;;
        4)
            echo ""
            read -p "  Yeni Resim Tam Yolu: " yeni_r
            if [ -f "$yeni_r" ]; then
                VARSAYILAN_RESIM="$yeni_r"; _kaydet_ayarlar
                echo -e "  ${GREEN}✓ Kapak güncellendi.${RESET}"
            else
                echo -e "  ${RED}✗ Dosya bulunamadı!${RESET}"
            fi
            sleep 1; ana_menu ;;
        5) adlandirma_menu ;;
        6) echo -e "  ${CYAN}👋 SAMIULLAH DILSUZ iyi günler diler!${RESET}"; exit 0 ;;
        *) echo -e "  ${RED}✗ Geçersiz!${RESET}"; sleep 1; ana_menu ;;
    esac
}

ana_menu
EOF
chmod +x ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh
echo "Samiullah Dilsuz Scripti Sıfır Hata Moduyla Güncellendi!"
